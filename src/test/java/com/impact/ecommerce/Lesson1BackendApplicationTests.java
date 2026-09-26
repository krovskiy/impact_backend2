package com.impact.ecommerce;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@org.springframework.test.context.ActiveProfiles("test")
@SpringBootTest
@AutoConfigureMockMvc
class Lesson1BackendApplicationTests {
    @Autowired
    private MockMvc mvc;

    @Test
    void homePageUsesFrontendIndex() throws Exception {
        mvc.perform(get("/")).andExpect(status().isOk())
                .andExpect(forwardedUrl("index.html"));
        mvc.perform(get("/index.html")).andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().bytes(Files.readAllBytes(Path.of("src", "main", "resources", "static", "index.html"))));
    }

    @Test
    void apiStillWorksAlongsideFrontend() throws Exception {
        mvc.perform(get("/api/practice")).andExpect(status().isOk())
                .andExpect(content().string("api initialised"));
    }

    @Test
    void frontendRepositoryFilesAreNotPublic() throws Exception {
        for (String path : new String[]{"/.git/config", "/package.json", "/src/app/App.jsx", "/README.md"}) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
        }
    }

    @Test
    void completedPracticeResponsesMatchLessonText() throws Exception {
        String body = "{\"name\":\"demo\"}";
        String[] methods = {"POST", "PUT", "PATCH", "DELETE"};
        String[] prefixes = {"youve posted: ", "your update is : ", "you have updated the : ", "youve deleted : "};
        for (int i = 0; i < methods.length; i++) {
            mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                    .request(org.springframework.http.HttpMethod.valueOf(methods[i]), "/api/practice")
                    .contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isOk()).andExpect(content().string(prefixes[i] + body));
        }
    }

    @Test
    void completedCorsAllowsEveryLessonMethod() throws Exception {
        for (String method : new String[]{"GET", "POST", "PUT", "PATCH", "DELETE"}) {
            mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                    .options("/api/practice").header("Origin", "http://localhost:5500")
                    .header("Access-Control-Request-Method", method))
                    .andExpect(status().isOk())
                    .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5500"))
                    .andExpect(header().string("Access-Control-Allow-Methods", org.hamcrest.Matchers.containsString(method)));
        }
    }
}
