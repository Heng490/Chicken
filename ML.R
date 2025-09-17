# =====================================
# Chicken breed prediction based on SNP using machine learning (10-fold CV, multiple models)
# Outputs total results + individual sample predictions + model metrics for each SNP count
# Complete and robust version
# =====================================

library(randomForest)
library(class)     # KNN
library(e1071)     # SVM
library(rpart)     # Decision Tree
library(adabag)    # AdaBoost
library(dplyr)
library(caret)     # confusionMatrix

# ==============================
# Data paths
# ==============================
data <- read.table("/path/to/your/data/all.txt", header = TRUE)
cv_base <- "/path/to/your/CV"

# ==============================
# Initialize results list
# ==============================
all_pred_list <- list()    # Store predictions for each test sample

# ==============================
# Loop for 10-fold CV
# ==============================
for (fold in 1:10) {
  cat("Processing CV fold:", fold, "\n")
  cv_dir <- file.path(cv_base, paste0("CV", fold))
  
  train_id <- read.table(file.path(cv_dir, "train.txt"), header = FALSE)
  test_id  <- read.table(file.path(cv_dir, "test.txt"), header = FALSE)
  
  train_data <- data[data$id %in% train_id$V1, ]
  test_data  <- data[data$id %in% test_id$V1, ]
  
  # -----------------------------
  # Loop for different SNP counts
  # -----------------------------
  for (n in seq(2, 30, by = 2)) {
    snp_file <- file.path(cv_dir, paste0("snp", n, ".txt"))
    if (!file.exists(snp_file)) next
    
    snp <- read.table(snp_file, header = FALSE)
    snp_cols <- intersect(snp$V1, colnames(train_data))
    
    if(length(snp_cols) == 0) next  # Skip if no valid SNPs
    
    train_snp <- train_data %>% select(id, group, all_of(snp_cols))
    test_snp  <- test_data %>% select(id, group, all_of(snp_cols))
    
    X_train <- train_snp[, -c(1,2)]
    y_train <- train_snp$group
    X_test  <- test_snp[, -c(1,2)]
    y_test  <- test_snp$group
    
    # ------------------------------
    # Model training and prediction
    # ------------------------------
    knn_pred <- knn(X_train, X_test, cl = y_train)
    svm_pred <- predict(svm(factor(y_train) ~ ., data = data.frame(y_train, X_train)), X_test)
    rf_pred  <- predict(randomForest(factor(y_train) ~ ., data = data.frame(y_train, X_train)), X_test)
    dt_pred  <- predict(rpart(factor(y_train) ~ ., data = data.frame(y_train, X_train), method = "class"),
                        X_test, type = "class")
    ab_pred_class <- predict.boosting(
      boosting(group ~ ., data = data.frame(group = factor(y_train), X_train), boos = TRUE, mfinal = 50),
      newdata = data.frame(X_test)
    )$class
    
    # ------------------------------
    # Save prediction results for each test sample
    # ------------------------------
    pred_df <- data.frame(
      CV_fold = fold,
      id = test_snp$id,
      num_snp = n,
      group = y_test,
      KNN = knn_pred,
      SVM = svm_pred,
      RF  = rf_pred,
      DT  = dt_pred,
      AB  = ab_pred_class
    )
    all_pred_list[[length(all_pred_list)+1]] <- pred_df
  }
}

# ==============================
# Combine all test sample prediction results
# ==============================
all_pred <- do.call(rbind, all_pred_list)

write.table(all_pred, file = "prediction_results_CV_total.txt",
            sep = "\t", row.names = FALSE, quote = FALSE)

# ==============================
# Calculate overall metrics by model + SNP count (robust version)
# ==============================
summary_metrics <- lapply(unique(all_pred$num_snp), function(n_snp){
  snp_data <- all_pred[all_pred$num_snp == n_snp, ]
  if(nrow(snp_data) == 0) return(NULL)  # Skip empty groups
  
  lapply(c("KNN","SVM","RF","DT","AB"), function(m){
    pred <- factor(snp_data[[m]], levels = unique(snp_data$group))
    truth <- factor(snp_data$group, levels = unique(snp_data$group))
    
    # If there are less than 2 classes in the test set, return NA
    if(length(levels(truth)) < 2) {
      return(data.frame(
        num_snp = n_snp,
        model = m,
        Accuracy = NA,
        Balanced_Accuracy = NA,
        Sensitivity = NA,
        Specificity = NA,
        F1 = NA
      ))
    }
    
    cm <- confusionMatrix(pred, truth)
    
    data.frame(
      num_snp = n_snp,
      model = m,
      Accuracy = cm$overall['Accuracy'],
      Balanced_Accuracy = mean(cm$byClass[,"Balanced Accuracy"], na.rm = TRUE),
      Sensitivity = mean(cm$byClass[,"Sensitivity"], na.rm = TRUE),
      Specificity = mean(cm$byClass[,"Specificity"], na.rm = TRUE),
      F1 = mean(cm$byClass[,"F1"], na.rm = TRUE)
    )
  }) %>% bind_rows()
}) %>% bind_rows()

write.table(summary_metrics, file = "model_metrics_CV_total.txt",
            sep = "\t", row.names = FALSE, quote = FALSE)

# ==============================
# Split predictions by model for each sample
# ==============================
for (m in c("KNN","SVM","RF","DT","AB")) {
  pred_m <- all_pred %>%
    select(id, num_snp, group, all_of(m))
  
  write.table(pred_m, file = paste0("prediction_results_", m, "_CV.txt"),
              sep = "\t", row.names = FALSE, quote = FALSE)
}

cat("All CV folds processed. Total predictions and overall metrics saved.\n")
