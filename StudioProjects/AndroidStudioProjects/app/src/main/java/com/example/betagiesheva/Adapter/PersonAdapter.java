package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.Model.Person;
import com.example.betagiesheva.R;


import java.util.ArrayList;
/* loaded from: classes4.dex */
public class PersonAdapter extends RecyclerView.Adapter<PersonAdapter.ViewHolder> {
    private Context context;
    private ArrayList<Person> personList;

    public PersonAdapter(Context context, ArrayList<Person> personList) {
        this.context = context;
        this.personList = personList;
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(this.context).inflate(R.layout.item_person, parent, false);
        return new ViewHolder(view);
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public void onBindViewHolder(ViewHolder holder, int position) {
        final Person person = this.personList.get(position);
        holder.nameTextView.setText(person.getName());
        holder.addressTextView.setText(person.getAddress());
        holder.numberTextView.setText(person.getNumber());
        holder.itemView.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.PersonAdapter$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                PersonAdapter.this.m841lambda$onBindViewHolder$0$comexamplebetagiesevaPersonAdapter(person, view);
            }
        });
        Glide.with(this.context).load(person.getImageUrl()).placeholder(R.drawable.man).error(R.drawable.man).into(holder.imageView);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onBindViewHolder$0$com-example-betagieseva-PersonAdapter  reason: not valid java name */
    public /* synthetic */ void m841lambda$onBindViewHolder$0$comexamplebetagiesevaPersonAdapter(Person person, View v) {
        Intent intent = new Intent("android.intent.action.DIAL");
        intent.setData(Uri.parse("tel:" + person.getNumber()));
        this.context.startActivity(intent);
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public int getItemCount() {
        return this.personList.size();
    }

    /* loaded from: classes4.dex */
    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView addressTextView;
        ImageView imageView;
        TextView nameTextView;
        TextView numberTextView;

        public ViewHolder(View itemView) {
            super(itemView);
            this.nameTextView = (TextView) itemView.findViewById(R.id.officer_name);
            this.addressTextView = (TextView) itemView.findViewById(R.id.officer_rank);
            this.numberTextView = (TextView) itemView.findViewById(R.id.officer_phone);
            this.imageView = (ImageView) itemView.findViewById(R.id.police);
        }
    }
}
