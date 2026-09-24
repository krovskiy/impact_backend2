package com.impact.ecommerce.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

public final class LessonTodo {
    private LessonTodo() { }
    public static ResponseStatusException required(String task) {
        return new ResponseStatusException(HttpStatus.NOT_IMPLEMENTED,
                "Complete TODO " + task + " first (see the matching lesson checklist).");
    }
}
