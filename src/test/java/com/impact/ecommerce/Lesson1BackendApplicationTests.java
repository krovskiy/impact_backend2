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
                .andExpect(content().bytes(Files.readAllBytes(Path.of("frontend", "index.html"))));
    }

    @Test
    void apiStillWorksAlongsideFrontend() throws Exception {
        mvc.perform(get("/api/practice")).andExpect(status().isOk())
                .andExpect(content().string("api initialised"));
    }

    @Test
    void frontendRepositoryFilesAreNotPublic() throws Exception {
        for (String path : new String[]{"/.git/config", "/package.json", "/src/app/App.jsx", "/README.md"}) {
            mvc.perform(get(path)).andExpect(status().isNotFound());
        }
    }
}
