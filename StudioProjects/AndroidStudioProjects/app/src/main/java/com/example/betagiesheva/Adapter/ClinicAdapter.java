package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.betagiesheva.AddClinicActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.Clinic;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;

import java.util.List;

import de.hdodenhof.circleimageview.CircleImageView;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.helper.AuthRequest;

public class ClinicAdapter extends RecyclerView.Adapter<ClinicAdapter.ClinicViewHolder> {

    private final Context context;
    private List<Clinic> clinicList;
    private final OnClinicClickListener listener;
    private final SessionManager sessionManager;

    public interface OnClinicClickListener {
        void onClinicClick(int position);
    }

    public ClinicAdapter(Context context, List<Clinic> clinicList, OnClinicClickListener listener) {
        this.context = context;
        this.clinicList = clinicList;
        this.listener = listener;
        this.sessionManager = new SessionManager(context);
    }

    @NonNull
    @Override
    public ClinicViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_clinic, parent, false);
        return new ClinicViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ClinicViewHolder holder, int position) {
        Clinic clinic = clinicList.get(position);

        // Bind text
        holder.clinicName.setText(clinic.getName() != null ? clinic.getName() : "Unknown Clinic");
        holder.clinicAddress.setText(clinic.getAddress() != null ? clinic.getAddress() : "Address not available");
        holder.clinicPhone.setText(clinic.getPhoneNumber() != null ? clinic.getPhoneNumber() : "N/A");

        // Load image
        if (clinic.getImg() != null && !clinic.getImg().isEmpty()) {
            Glide.with(context)
                    .load(clinic.getImg())
                    .placeholder(R.drawable.ic_clinic)
                    .error(R.drawable.ic_clinic)
                    .into(holder.clinicImage);
        } else {
            holder.clinicImage.setImageResource(R.drawable.ic_clinic);
        }

        // Regular item click
        holder.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClinicClick(position);
        });

        // Call button
        holder.callButton.setOnClickListener(v -> {
            String phone = clinic.getPhoneNumber();
            if (phone != null && !phone.isEmpty()) {
                Intent intent = new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + phone));
                context.startActivity(intent);
            }
        });

        // Show admin buttons
        boolean isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());
        holder.bottomRow.setVisibility(isAdmin ? View.VISIBLE : View.GONE);

        if (isAdmin) {
            // Edit button
            holder.btnEdit.setOnClickListener(v -> {
                if (position >= 0 && position < clinicList.size()) {
                    Clinic selectedClinic = clinicList.get(position);
                    Intent intent = new Intent(context, AddClinicActivity.class);
                    intent.putExtra("clinic_data", selectedClinic);
                    context.startActivity(intent);
                }
            });

            // Delete button
            holder.btnDelete.setOnClickListener(v -> {
                if (position >= 0 && position < clinicList.size()) {
                    deleteClinic(clinicList.get(position).getId(), position);
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        return clinicList != null ? clinicList.size() : 0;
    }

    public void updateList(List<Clinic> newList) {
        if (newList != null) {
            this.clinicList = newList;
            notifyDataSetChanged();
        }
    }

    public void updateItem(Clinic clinic, int position) {
        if (position >= 0 && position < clinicList.size()) {
            clinicList.set(position, clinic);
            notifyItemChanged(position);
        }
    }

    private void deleteClinic(String clinicId, int position) {
        String url = Config.DELETE_CLINIC + "?id=" + clinicId;

        AuthRequest request = new AuthRequest(Request.Method.GET, url,
                response -> {
                    Toast.makeText(context, "Clinic deleted", Toast.LENGTH_SHORT).show();
                    clinicList.remove(position);
                    notifyItemRemoved(position);
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(context, "Delete failed", Toast.LENGTH_SHORT).show();
                },
                context);

        Config.getInstance(context).addToRequestQueue(request);
    }

    static class ClinicViewHolder extends RecyclerView.ViewHolder {
        TextView clinicName, clinicAddress, clinicPhone;
        CircleImageView clinicImage;
        View callButton;
        LinearLayout bottomRow;
        AppCompatButton btnEdit, btnDelete;

        public ClinicViewHolder(@NonNull View itemView) {
            super(itemView);
            clinicName = itemView.findViewById(R.id.clinic_name);
            clinicAddress = itemView.findViewById(R.id.clinic_address);
            clinicPhone = itemView.findViewById(R.id.clinic_phone);
            clinicImage = itemView.findViewById(R.id.clinic_image);
            callButton = itemView.findViewById(R.id.lottie_call);
            bottomRow = itemView.findViewById(R.id.bottom_row);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            btnDelete = itemView.findViewById(R.id.btn_delete);
        }
    }
}
