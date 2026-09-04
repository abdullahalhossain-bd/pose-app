package com.example.betagiesheva.helper;

import android.content.Context;

import com.android.volley.AuthFailureError;
import com.android.volley.Response;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.SessionManager;

import java.util.HashMap;
import java.util.Map;

/**
 * AuthRequest — StringRequest subclass that automatically attaches
 * the JWT `Authorization: Bearer <token>` header.
 *
 * Use this instead of {@code new StringRequest(...)} for ANY request
 * to an endpoint that calls the server's {@code authUser()} helper
 * (i.e., all add/update/delete endpoints).
 *
 * Without this header, the server responds with HTTP 401 Unauthorized.
 */
public class AuthRequest extends StringRequest {

    private final Context context;

    /**
     * @param method        HTTP method (Request.Method.POST, etc.)
     * @param url           endpoint URL
     * @param listener      success listener
     * @param errorListener error listener
     * @param context       any context (used to read the JWT from SessionManager)
     */
    public AuthRequest(int method, String url,
                       Response.Listener<String> listener,
                       Response.ErrorListener errorListener,
                       Context context) {
        super(method, url, listener, errorListener);
        this.context = context.getApplicationContext();
    }

    @Override
    public Map<String, String> getHeaders() throws AuthFailureError {
        Map<String, String> headers = new HashMap<>();
        headers.put("Accept", "application/json");

        if (context != null) {
            SessionManager session = new SessionManager(context);
            String token = session.getToken();
            if (token != null && !token.isEmpty()) {
                headers.put("Authorization", "Bearer " + token);
            }
        }
        return headers;
    }
}
