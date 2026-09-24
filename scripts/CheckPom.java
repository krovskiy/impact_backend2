import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.regex.Pattern;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.*;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.w3c.dom.*;
import org.xml.sax.SAXParseException;
import org.xml.sax.helpers.DefaultHandler;

/** Shared by all launchers; runs directly with the Java 21 JDK, without Maven. */
class CheckPom {
    static final String MAVEN_NS = "http://maven.apache.org/POM/4.0.0";

    public static void main(String[] args) {
        try {
            check(Path.of(args[0]));
        } catch (Exception error) {
            System.err.println("POM CHECK STOPPED: " + error.getMessage());
            System.err.println("Open pom.xml. Put dependencies inside <project><dependencies>, before </project>."
                    + " Fix incomplete/duplicate XML manually, save, then rerun the launcher.");
            System.exit(1);
        }
    }

    static Document parse(byte[] xml) throws Exception {
        var factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
        var builder = factory.newDocumentBuilder();
        builder.setErrorHandler(new DefaultHandler() {
            @Override public void error(SAXParseException e) throws SAXParseException { throw e; }
            @Override public void fatalError(SAXParseException e) throws SAXParseException { throw e; }
        });
        return builder.parse(new ByteArrayInputStream(xml));
    }

    static boolean named(Node node, String name, String namespace) {
        return node instanceof Element && name.equals(node.getLocalName())
                && Objects.equals(namespace, node.getNamespaceURI());
    }

    static List<Element> children(Element parent, String name) {
        var result = new ArrayList<Element>();
        for (Node node = parent.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (named(node, name, parent.getNamespaceURI())) result.add((Element) node);
        }
        return result;
    }

    static String field(Element dependency, String name, String fallback) {
        var matches = children(dependency, name);
        if (matches.size() > 1) throw new IllegalArgumentException("Repeated dependency field: " + name);
        return matches.isEmpty() ? fallback : matches.get(0).getTextContent().trim();
    }

    static String key(Element dependency) {
        var group = field(dependency, "groupId", "");
        var artifact = field(dependency, "artifactId", "");
        if (group.isBlank() || artifact.isBlank())
            throw new IllegalArgumentException("A dependency is missing groupId or artifactId.");
        return group + ":" + artifact + ":" + field(dependency, "type", "jar")
                + ":" + field(dependency, "classifier", "");
    }

    static void collect(Node parent, String namespace, List<Node> nodes, boolean allowWrapper) {
        for (Node node = parent.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (named(node, "dependency", namespace) || node.getNodeType() == Node.COMMENT_NODE) {
                nodes.add(node);
            } else if (allowWrapper && named(node, "dependencies", namespace)) {
                collect(node, namespace, nodes, false);
            } else if (node.getNodeType() != Node.TEXT_NODE || !node.getTextContent().isBlank()) {
                throw new IllegalArgumentException("Unexpected content after </project>; left unchanged.");
            }
        }
    }

    static void check(Path pom) throws Exception {
        byte[] original = Files.readAllBytes(pom);
        try {
            Document valid = parse(original);
            if (!"project".equals(valid.getDocumentElement().getLocalName()))
                throw new IllegalArgumentException("The XML root must be <project>.");
            return; // Valid files remain byte-for-byte unchanged.
        } catch (SAXParseException invalid) {
            // Only repair a complete project followed by complete dependency snippets.
        }
        String text = new String(original, StandardCharsets.UTF_8);
        var ending = Pattern.compile("</project\\s*>").matcher(text);
        Document document = null;
        int split = -1;
        while (ending.find()) {
            try {
                document = parse(text.substring(0, ending.end()).getBytes(StandardCharsets.UTF_8));
                if ("project".equals(document.getDocumentElement().getLocalName())) {
                    split = ending.end();
                    break;
                }
            } catch (Exception ignored) { }
        }
        if (split < 0) throw new IllegalArgumentException("pom.xml contains malformed XML; left unchanged.");
        Element project = document.getDocumentElement();
        String namespace = project.getNamespaceURI();
        if (namespace != null && !MAVEN_NS.equals(namespace))
            throw new IllegalArgumentException("Unrecognized project XML namespace; left unchanged.");
        String wrapper = "<dependencies" + (namespace == null ? "" : " xmlns=\"" + namespace + "\"") + ">";
        Document suffix = parse((wrapper + text.substring(split) + "</dependencies>").getBytes(StandardCharsets.UTF_8));
        var appended = new ArrayList<Node>();
        collect(suffix.getDocumentElement(), namespace, appended, true);
        if (appended.stream().noneMatch(node -> node instanceof Element))
            throw new IllegalArgumentException("No complete trailing dependencies found; left unchanged.");

        var sections = children(project, "dependencies");
        if (sections.size() > 1)
            throw new IllegalArgumentException("Multiple project dependencies sections; left unchanged.");
        Element dependencies = sections.isEmpty()
                ? document.createElementNS(namespace, "dependencies") : sections.get(0);
        Set<String> keys = new HashSet<>();
        for (var dependency : children(dependencies, "dependency")) keys.add(key(dependency));
        for (Node node : appended) {
            if (node instanceof Element dependency && !keys.add(key(dependency)))
                throw new IllegalArgumentException("Duplicate dependency " + key(dependency) + "; left unchanged.");
            dependencies.appendChild(document.importNode(node, true));
        }
        if (sections.isEmpty()) project.appendChild(dependencies);

        var factory = TransformerFactory.newInstance();
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_STYLESHEET, "");
        var transformer = factory.newTransformer();
        transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        var output = new ByteArrayOutputStream();
        transformer.transform(new DOMSource(document), new StreamResult(output));
        byte[] repaired = output.toByteArray();
        parse(repaired); // Validate before touching the original.

        Path backup = pom.resolveSibling("pom.xml.before-setup-fix.bak");
        if (Files.exists(backup))
            throw new IllegalArgumentException("Move the existing " + backup + " backup aside, then retry.");
        if (!Arrays.equals(original, Files.readAllBytes(pom)))
            throw new IllegalArgumentException("pom.xml changed during the check. Save it and retry.");
        Files.copy(pom, backup); // Never overwrite a previous backup.
        Path temporary = Files.createTempFile(pom.toAbsolutePath().getParent(), ".pom-fix-", ".tmp");
        try {
            Files.write(temporary, repaired);
            try {
                Files.move(temporary, pom, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
            } catch (AtomicMoveNotSupportedException ignored) {
                Files.move(temporary, pom, StandardCopyOption.REPLACE_EXISTING);
            }
        } finally {
            Files.deleteIfExists(temporary);
        }
        System.out.println("Fixed pom.xml: moved trailing dependencies inside <project><dependencies>.");
        System.out.println("Original saved as " + backup + ". Reload Maven in IntelliJ if it is open.");
    }
}
