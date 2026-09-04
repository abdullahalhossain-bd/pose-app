package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.helper.AuthRequest;
import com.example.betagiesheva.AddUnifiedSpecialistDoctorActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.UnifiedSpecialistDoctor;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;

import java.util.List;

public class UnifiedSpecialistDoctorAdapter extends RecyclerView.Adapter<UnifiedSpecialistDoctorAdapter.ViewHolder> {

    private final Context context;
    private final List<UnifiedSpecialistDoctor> doctorList;
    private final OnDoctorClickListener listener;
    private final SessionManager sessionManager;

    public interface OnDoctorClickListener {
        void onCallButtonClick(UnifiedSpecialistDoctor doctor);
        void onDetailsButtonClick(UnifiedSpecialistDoctor doctor);
    }

    public UnifiedSpecialistDoctorAdapter(Context context, List<UnifiedSpecialistDoctor> doctorList, OnDoctorClickListener listener) {
        this.context = context;
        this.doctorList = doctorList;
        this.listener = listener;
        this.sessionManager = new SessionManager(context);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_unified_specialist_doctor, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        UnifiedSpecialistDoctor doctor = doctorList.get(position);

        // Set doctor name with null safety
        holder.nameTextView.setText(doctor.getName() != null && !doctor.getName().isEmpty()
                ? doctor.getName()
                : "নাম পাওয়া যায়নি");

        // Set qualifications with null safety
        holder.qualificationsTextView.setText(doctor.getQualifications() != null && !doctor.getQualifications().isEmpty()
                ? doctor.getQualifications()
                : "যোগ্যতা: তথ্য নেই");

        // Set address/workplace with null safety
        holder.addressTextView.setText(getDisplayAddress(doctor));

        // Set specialization details with null safety
        holder.detailsTextView.setText(doctor.getSpecialization() != null && !doctor.getSpecialization().isEmpty()
                ? doctor.getSpecialization()
                : "বিশেষত্ব: তথ্য নেই");

        // Load doctor's image using Glide with proper error handling
        loadDoctorImage(holder.doctorImageView, doctor);

        // Set button click listeners
        holder.callButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onCallButtonClick(doctor);
            }
        });

        holder.detailsButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onDetailsButtonClick(doctor);
            }
        });

        // Show admin buttons (edit/delete) for admin users
        boolean isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());
        holder.bottomRow.setVisibility(isAdmin ? View.VISIBLE : View.GONE);

        if (isAdmin) {
            // Edit button
            holder.btnEdit.setOnClickListener(v -> {
                if (position >= 0 && position < doctorList.size()) {
                    UnifiedSpecialistDoctor selectedDoctor = doctorList.get(position);
                    Intent intent = new Intent(context, AddUnifiedSpecialistDoctorActivity.class);
                    intent.putExtra("doctor_data", selectedDoctor);
                    intent.putExtra("doctor_type", selectedDoctor.getDoctorType());
                    context.startActivity(intent);
                }
            });

            // Delete button
            holder.btnDelete.setOnClickListener(v -> {
                if (position >= 0 && position < doctorList.size()) {
                    deleteDoctor(doctorList.get(position).getId(), position);
                }
            });
        }
    }

    private String getDisplayAddress(UnifiedSpecialistDoctor doctor) {
        // Priority: Chamber > Workplace > Address
        if (doctor.getChamber() != null && !doctor.getChamber().isEmpty()) {
            return doctor.getChamber();
        } else if (doctor.getWorkplace() != null && !doctor.getWorkplace().isEmpty()) {
            return doctor.getWorkplace();
        } else if (doctor.getAddress() != null && !doctor.getAddress().isEmpty()) {
            return doctor.getAddress();
        } else {
            return "ঠিকানা: তথ্য নেই";
        }
    }

    private void loadDoctorImage(ImageView imageView, UnifiedSpecialistDoctor doctor) {
        // Default placeholder based on doctor type
        int placeholder = getPlaceholderForDoctorType(doctor.getDoctorType());

        if (doctor.getImageUrl() != null && !doctor.getImageUrl().isEmpty()) {
            Glide.with(context)
                    .load(doctor.getImageUrl())
                    .placeholder(placeholder)
                    .error(placeholder)
                    .centerCrop()
                    .into(imageView);
        } else {
            imageView.setImageResource(placeholder);
        }
    }

    private int getPlaceholderForDoctorType(String doctorType) {
        if (doctorType == null) {
            return R.drawable.cardiologist; // Default
        }

        switch (doctorType.toLowerCase()) {
            case "gynecology":
                return R.drawable.gynecologist;
            case "dental":
                return R.drawable.dentist;
            case "orthopedics":
                return R.drawable.orthopedic;
            case "pediatrics":
                return R.drawable.pre;
            case "psychiatry":
                return R.drawable.psy;
            case "eye":
                return R.drawable.ophthalmologist;
            case "ent":
                return R.drawable.nak;
            case "kidney":
                return R.drawable.kidney;
            case "medicine":
                return R.drawable.medicine;
            case "neurology":
                return R.drawable.neurologist;
            case "skin":
                return R.drawable.dermatologist;
            case "cardiology":
                return R.drawable.cardiologist;
            default:
                return R.drawable.cardiologist; // Default fallback
        }
    }

    @Override
    public int getItemCount() {
        return doctorList != null ? doctorList.size() : 0;
    }

    public void updateDoctorList(List<UnifiedSpecialistDoctor> newDoctorList) {
        if (doctorList != null && newDoctorList != null) {
            doctorList.clear();
            doctorList.addAll(newDoctorList);
            notifyDataSetChanged();
        }
    }

    private void deleteDoctor(String doctorId, int position) {
        String url = Config.DELETE_SPECIALIST_DOCTOR + "?id=" + doctorId;

        AuthRequest request = new AuthRequest(Request.Method.GET, url,
                response -> {
                    Toast.makeText(context, "ডাক্তার ডিলিট হয়েছে", Toast.LENGTH_SHORT).show();
                    doctorList.remove(position);
                    notifyItemRemoved(position);
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(context, "ডিলিট ব্যর্থ হয়েছে", Toast.LENGTH_SHORT).show();
                },
                context);

        Config.getInstance(context).addToRequestQueue(request);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView doctorImageView;
        TextView nameTextView;
        TextView qualificationsTextView;
        TextView addressTextView;
        TextView detailsTextView;
        Button callButton;
        Button detailsButton;
        LinearLayout bottomRow;
        AppCompatButton btnEdit, btnDelete;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            doctorImageView = itemView.findViewById(R.id.unified_specialist_doctor_image);
            nameTextView = itemView.findViewById(R.id.unified_specialist_doctor_name);
            qualificationsTextView = itemView.findViewById(R.id.unified_specialist_doctor_qualifications);
            addressTextView = itemView.findViewById(R.id.unified_specialist_doctor_address);
            detailsTextView = itemView.findViewById(R.id.unified_specialist_doctor_details);
            callButton = itemView.findViewById(R.id.call_button);
            detailsButton = itemView.findViewById(R.id.details_button);
            bottomRow = itemView.findViewById(R.id.bottom_row);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            btnDelete = itemView.findViewById(R.id.btn_delete);
        }
    }
}