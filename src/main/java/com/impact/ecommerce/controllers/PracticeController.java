package com.impact.ecommerce.controllers;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

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
@Tag(name = "Lesson 1 practice")
@RestController
@RequestMapping("/api/practice")
public class PracticeController {

    @Operation(summary = "Practice GET")
    @ApiResponse(responseCode = "200", description = "Practice response")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @GetMapping
    public ResponseEntity<String> getPractice() {
        return ResponseEntity.ok("api initialised");
    }

    @Operation(summary = "Practice POST")
    @ApiResponse(responseCode = "200", description = "Practice response")
    @ApiResponse(responseCode = "400", description = "Missing body")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @PostMapping
    public ResponseEntity<String> postPractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: youve posted: {body}
        return ResponseEntity.ok("TODO: POST response for " + body);
    }

    @Operation(summary = "Practice PUT")
    @ApiResponse(responseCode = "200", description = "Practice response")
    @ApiResponse(responseCode = "400", description = "Missing body")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @PutMapping
    public ResponseEntity<String> putPractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: your update is : {body}
        return ResponseEntity.ok("TODO: PUT response for " + body);
    }

    @Operation(summary = "Practice PATCH")
    @ApiResponse(responseCode = "200", description = "Practice response")
    @ApiResponse(responseCode = "400", description = "Missing body")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @PatchMapping
    public ResponseEntity<String> patchPractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: you have updated the : {body}
        return ResponseEntity.ok("TODO: PATCH response for " + body);
    }

    @Operation(summary = "Practice DELETE")
    @ApiResponse(responseCode = "200", description = "Practice response")
    @ApiResponse(responseCode = "400", description = "Missing body")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @DeleteMapping
    public ResponseEntity<String> deletePractice(@RequestBody String body) {
        // TODO Lesson 1: exact response should be: youve deleted : {body}
        return ResponseEntity.ok("TODO: DELETE response for " + body);
    }
}
