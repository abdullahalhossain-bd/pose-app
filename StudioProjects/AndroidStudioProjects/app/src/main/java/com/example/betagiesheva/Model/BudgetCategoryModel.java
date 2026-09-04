package com.example.betagiesheva.Model;

public class BudgetCategoryModel {

    private String categoryName;
    private double allocatedAmount;
    private double spentAmount;

    public BudgetCategoryModel(String categoryName, double allocatedAmount, double spentAmount) {
        this.categoryName = categoryName;
        this.allocatedAmount = allocatedAmount;
        this.spentAmount = spentAmount;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public double getAllocatedAmount() {
        return allocatedAmount;
    }

    public double getSpentAmount() {
        return spentAmount;
    }

    public double getRemainingAmount() {
        return allocatedAmount - spentAmount;
    }

    public int getProgressPercent() {
        if (allocatedAmount <= 0) return 0;
        return (int) ((spentAmount / allocatedAmount) * 100);
    }
}
