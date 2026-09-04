package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.betagiesheva.Model.BudgetCategoryModel;
import com.example.betagiesheva.R;

import java.util.ArrayList;

public class BudgetCategoryAdapter extends RecyclerView.Adapter<BudgetCategoryAdapter.ViewHolder> {

    Context context;
    ArrayList<BudgetCategoryModel> list;

    public BudgetCategoryAdapter(Context context, ArrayList<BudgetCategoryModel> list) {
        this.context = context;
        this.list = list;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context)
                .inflate(R.layout.row_budget_category, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        BudgetCategoryModel model = list.get(position);

        holder.categoryNameText.setText(model.getCategoryName());

        holder.amountText.setText(
                "বরাদ্দ: ৳ " + model.getAllocatedAmount()
                        + " | ব্যয়: ৳ " + model.getSpentAmount()
        );

        holder.remainingText.setText(
                "অবশিষ্ট: ৳ " + model.getRemainingAmount()
        );

        holder.categoryProgress.setProgress(model.getProgressPercent());
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {

        TextView categoryNameText, amountText, remainingText;
        ProgressBar categoryProgress;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            categoryNameText = itemView.findViewById(R.id.categoryNameText);
            amountText = itemView.findViewById(R.id.amountText);
            remainingText = itemView.findViewById(R.id.remainingText);
            categoryProgress = itemView.findViewById(R.id.categoryProgress);
        }
    }
}
