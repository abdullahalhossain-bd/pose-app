package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;
import androidx.recyclerview.widget.RecyclerView;

import com.example.betagiesheva.R;
import com.example.betagiesheva.Model.EmergencyNumber;

import java.util.List;
/* loaded from: classes4.dex */
public class EmergencyAdapter extends RecyclerView.Adapter<EmergencyAdapter.EmergencyViewHolder> {
    private Context context;
    private List<EmergencyNumber> emergencyList;

    public EmergencyAdapter(List<EmergencyNumber> emergencyList, Context context) {
        this.emergencyList = emergencyList;
        this.context = context;
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public EmergencyViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_emergency_number, parent, false);
        return new EmergencyViewHolder(view);
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public void onBindViewHolder(EmergencyViewHolder holder, int position) {
        final EmergencyNumber currentItem = this.emergencyList.get(position);
        holder.nameTextView.setText(currentItem.getName());
        holder.numberTextView.setText(currentItem.getNumber());
        holder.callButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.EmergencyAdapter$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                EmergencyAdapter.this.m437x61afcf58(currentItem, view);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onBindViewHolder$0$com-example-betagieseva-EmergencyAdapter  reason: not valid java name */
    public /* synthetic */ void m437x61afcf58(EmergencyNumber currentItem, View v) {
        String phoneNumber = "tel:" + currentItem.getNumber();
        Intent callIntent = new Intent("android.intent.action.DIAL", Uri.parse(phoneNumber));
        this.context.startActivity(callIntent);
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public int getItemCount() {
        return this.emergencyList.size();
    }

    /* loaded from: classes4.dex */
    public static class EmergencyViewHolder extends RecyclerView.ViewHolder {
        public ImageButton callButton;
        public TextView nameTextView;
        public TextView numberTextView;

        public EmergencyViewHolder(View itemView) {
            super(itemView);
            this.nameTextView = (TextView) itemView.findViewById(R.id.tv_emergency_name);
            this.numberTextView = (TextView) itemView.findViewById(R.id.tv_emergency_number);
            this.callButton = (ImageButton) itemView.findViewById(R.id.btn_call);
        }
    }
}
