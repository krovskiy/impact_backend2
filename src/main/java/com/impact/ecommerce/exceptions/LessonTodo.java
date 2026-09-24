package com.impact.ecommerce.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

public final class LessonTodo {
    private LessonTodo() { }
    public static ResponseStatusException required(String task) {
        return new ResponseStatusException(HttpStatus.NOT_IMPLEMENTED,
                "Complete TODO Lesson 2 " + task + " first (see LESSON2_CHECKLIST.md).");
    }
}
