package com.impact.ecommerce.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Lesson 1 practice endpoint.
 *
 * GET is implemented as an example.
 * The other methods are intentionally almost finished: students only need to replace
 * the TODO responses with the exact lesson text.
 */
@RestController
@RequestMapping("/api/practice")
public class PracticeController {

    @GetMapping
    public ResponseEntity<String> getPractice() {
        return ResponseEntity.ok("api initialised");
    }

    @PostMapping
    public ResponseEntity<String> postPractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: youve posted: {body}
        return ResponseEntity.ok("TODO: POST response for " + body);
    }

    @PutMapping
    public ResponseEntity<String> putPractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: your update is : {body}
        return ResponseEntity.ok("TODO: PUT response for " + body);
    }

    @PatchMapping
    public ResponseEntity<String> patchPractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: you have updated the : {body}
        return ResponseEntity.ok("TODO: PATCH response for " + body);
    }

    @DeleteMapping
    public ResponseEntity<String> deletePractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: youve deleted : {body}
        return ResponseEntity.ok("TODO: DELETE response for " + body);
    }
}
