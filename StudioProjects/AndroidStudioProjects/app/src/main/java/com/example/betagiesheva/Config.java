package com.example.betagiesheva;

import android.content.Context;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.Volley;

public class Config {

    public static final String BASE_URL  = "https://admin.nagoriksheba.com/php/api/";

    /**
     * IMAGE_URL — points to /uploads/profiles/ ONLY.
     * Use this to load user profile images, where the server returns just a filename
     * (basename) in login.php and register.php responses.
     *
     * For ALL OTHER image types (donors, clinics, doctors, notices, business, govt items,
     * govt officers, persons), the server's `imageUrl()` helper ALREADY returns the FULL
     * URL (with correct subfolder). Do NOT prepend this constant to those URLs — use them
     * directly with Glide.
     */
    public static final String IMAGE_URL        = "https://admin.nagoriksheba.com/php/uploads/profiles/";
    public static final String UPLOADS_BASE_URL = "https://admin.nagoriksheba.com/php/uploads/";
    public static final String PREF_NAME = "user_pref";

    // ── Auth ──────────────────────────────────────────────────────────────
    public static final String REGISTER           = BASE_URL + "register.php";
    public static final String LOGIN              = BASE_URL + "login.php";
    public static final String PROFILE_URL        = BASE_URL + "profile.php";
    public static final String UPDATE_PROFILE_URL = BASE_URL + "update_profile.php";
    public static final String CHANGE_PASSWORD_URL= BASE_URL + "update_password.php";
    public static final String ADMIN_LOGIN_URL    = BASE_URL + "admin_login.php";

    // ── Notice ────────────────────────────────────────────────────────────
    public static final String NOTICE_LIST_URL  = BASE_URL + "get_notice.php";
    public static final String ADD_NOTICE_URL   = BASE_URL + "add_notice.php";
    public static final String UPDATE_NOTICE_URL= BASE_URL + "update_notice.php";
    public static final String DELETE_NOTICE_URL= BASE_URL + "delete_notice.php";

    // ── Budget ────────────────────────────────────────────────────────────
    public static final String BUDGET_DETAILS_URL = BASE_URL + "budget_details.php";

    // ── Business ──────────────────────────────────────────────────────────
    public static final String BUSINESS_ITEMS_URL          = BASE_URL + "get_unified_business.php";
    public static final String Add_BUSINESS_ITEMS_URL      = BASE_URL + "add_unified_business.php";
    public static final String UPDATE_UNIFIED_BUSINESS_ITEM= BASE_URL + "update_unified_business.php";
    public static final String DELETE_UNIFIED_BUSINESS_ITEM= BASE_URL + "delete_unified_business.php";

    // ── Blood Donor ───────────────────────────────────────────────────────
    // NOTE: server's get_donor.php expects ?name= (NOT ?search=) and ?blood_group=
    public static String GET_DONOR    = BASE_URL + "get_donor.php";
    public static String ADD_DONOR    = BASE_URL + "add_donor.php";
    public static String UPDATE_DONOR = BASE_URL + "update_donor.php";
    public static String DELETE_DONOR = BASE_URL + "delete_donor.php";

    // ── Clinic ────────────────────────────────────────────────────────────
    public static String Get_Clinic    = BASE_URL + "get_clinic.php";
    public static String ADD_CLINIC    = BASE_URL + "add_clinic.php";
    public static String UPDATE_CLINIC = BASE_URL + "update_clinic.php";
    public static String DELETE_CLINIC = BASE_URL + "delete_clinic.php";

    // ── Specialist Doctor ─────────────────────────────────────────────────
    public static String DOCTOR_LIST_URL        = BASE_URL + "doctors.php";
    public static String GET_SPECIALIST_DOCTOR  = BASE_URL + "get_specialist_doctor.php";
    public static String ADD_SPECIALIST_DOCTOR  = BASE_URL + "add_specialist_doctor.php";
    public static String UPDATE_SPECIALIST_DOCTOR = BASE_URL + "update_specialist_doctor.php";
    public static String DELETE_SPECIALIST_DOCTOR = BASE_URL + "delete_specialist_doctor.php";

    // ── Govt Item ─────────────────────────────────────────────────────────
    public static String GET_UNIFIED_GOVT_ITEM   = BASE_URL + "get_unified_govt_item.php";
    public static String ADD_UNIFIED_GOVT_ITEM    = BASE_URL + "add_unified_govt_item.php";
    public static String UPDATE_UNIFIED_GOVT_ITEM = BASE_URL + "update_unified_govt_item.php";
    public static String DELETE_UNIFIED_GOVT_ITEM = BASE_URL + "delete_unified_govt_item.php";

    // ── Govt Officer ──────────────────────────────────────────────────────
    public static String GET_UNIFIED_GOVT_OFFICER = BASE_URL + "get_unified_govt_officer.php";
    public static String ADD_UNIFIED_GOVT_OFFICER = BASE_URL + "add_unified_govt_officer.php";
    public static String UPDATE_UNIFIED_GOVT_OFFICER = BASE_URL + "update_unified_govt_officer.php";
    public static String DELETE_UNIFIED_GOVT_OFFICER = BASE_URL + "delete_unified_govt_officer.php";

    // ── Person Directory ──────────────────────────────────────────────────
    public static String ADD_UNIFIED_PERSON_URL = BASE_URL + "add_unified_person.php";
    public static String GET_UNIFIED_PERSON_URL = BASE_URL + "get_unified_person.php";
    public static String UPDATE_UNIFIED_PERSON  = BASE_URL + "update_unified_person.php";
    public static String DELETE_UNIFIED_PERSON  = BASE_URL + "delete_unified_person.php";

    // ── Complaints / Emergency / Notifications (Phase 6 endpoints) ────────
    public static final String SUBMIT_COMPLAINT_URL     = BASE_URL + "submit_complaint.php";
    public static final String GET_COMPLAINTS_URL       = BASE_URL + "get_complaints.php";
    public static final String UPDATE_COMPLAINT_STATUS_URL = BASE_URL + "update_complaint_status.php";
    public static final String GET_EMERGENCY_NUMBERS_URL= BASE_URL + "get_emergency_numbers.php";
    public static final String ADD_EMERGENCY_NUMBER_URL = BASE_URL + "add_emergency_number.php";
    public static final String UPDATE_EMERGENCY_NUMBER_URL = BASE_URL + "update_emergency_number.php";
    public static final String DELETE_EMERGENCY_NUMBER_URL = BASE_URL + "delete_emergency_number.php";
    public static final String GET_NOTIFICATIONS_URL    = BASE_URL + "get_notifications.php";
    public static final String ADD_NOTIFICATION_URL     = BASE_URL + "add_notification.php";
    public static final String DELETE_NOTIFICATION_URL  = BASE_URL + "delete_notification.php";

    // ── Admin Budget Management ───────────────────────────────────────────
    public static final String ADMIN_ADD_BUDGET_CATEGORY_URL    = BASE_URL + "admin_add_budget_category.php";
    public static final String ADMIN_UPDATE_BUDGET_CATEGORY_URL = BASE_URL + "admin_update_budget_category.php";
    public static final String ADMIN_DELETE_BUDGET_CATEGORY_URL = BASE_URL + "admin_delete_budget_category.php";

    // ── Admin User Management ─────────────────────────────────────────────
    public static final String ADMIN_LIST_USERS_URL      = BASE_URL + "admin_list_users.php";
    public static final String ADMIN_UPDATE_USER_ROLE_URL    = BASE_URL + "admin_update_user_role.php";
    public static final String ADMIN_UPDATE_USER_STATUS_URL  = BASE_URL + "admin_update_user_status.php";
    public static final String ADMIN_DASHBOARD_STATS_URL     = BASE_URL + "admin_dashboard_stats.php";

    // ── Volley Singleton ──────────────────────────────────────────────────
    private static Config instance;
    private RequestQueue requestQueue;
    private static Context ctx;

    private Config(Context context) {
        ctx = context.getApplicationContext();
        requestQueue = getRequestQueue();
    }

    public static synchronized Config getInstance(Context context) {
        if (instance == null) {
            instance = new Config(context);
        }
        return instance;
    }

    public RequestQueue getRequestQueue() {
        if (requestQueue == null) {
            requestQueue = Volley.newRequestQueue(ctx.getApplicationContext());
        }
        return requestQueue;
    }

    public <T> void addToRequestQueue(Request<T> req) {
        getRequestQueue().add(req);
    }
}