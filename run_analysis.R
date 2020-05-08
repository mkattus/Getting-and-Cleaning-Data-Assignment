## You should create one R script called run_analysis.R that does the following.

library(dplyr)
library(tibble)

## Before running, make sure UCI HAR data set unzipped in working directory
## 0. Read in data. Per directions "can be run as long as the Samsung data is in your working directory."

x_test <- read.table("./UCI HAR Dataset/test/X_test.txt")
y_test <- read.table("./UCI Har Dataset/test/y_test.txt")
subject_test <- read.table("./UCI HAR Dataset/test/subject_test.txt")
x_train <- read.table("./UCI HAR Dataset/train/X_train.txt")
y_train <- read.table("./UCI HAR Dataset/train/y_train.txt") 
subject_train <- read.table("./UCI HAR Dataset/train/subject_train.txt")
activities <- read.table("./UCI HAR Dataset/activity_labels.txt")
variables <- read.table("./UCI HAR Dataset/features.txt")
activity_labels <- read.table("./UCI HAR Dataset/activity_labels.txt", stringsAsFactors = FALSE)

## 1. Merge the training and the test sets to create one data set.

colnames(x_test) <- paste(colnames(x_test), variables$V2)       #merge and rename test data. Pasting column names ensures uniqueness 
y_test <- rename(y_test, activity = V1)
subject_test <- rename(subject_test, subjectID = V1)
test_data <- cbind(subject_test, y_test, x_test)

colnames(x_train) <- paste(colnames(x_train), variables$V2)     #merge and rename train data
y_train <- rename(y_train, activity = V1)       
subject_train <- rename(subject_train, subjectID = V1)
train_data <- cbind(subject_train, y_train, x_train)

data <- rbind(test_data, train_data)                            #merge test and train data


## 2. Extracts only the measurements on the mean and standard deviation for each measurement.

mean_cols <- grep("[Mm]ean", colnames(data), value = TRUE)
std_cols <- grep("[Ss]td", colnames(data), value = TRUE)
select_data <- select(data, subjectID, activity, mean_cols, std_cols)

## 3. Uses descriptive activity names to name the activities in the data set

for(i in seq_along(activity_labels$V2)){
        select_data$activity <- sub(activity_labels$V1[i], activity_labels$V2[i], select_data$activity)
}

## 4. Appropriately labels the data set with descriptive variable names.
## Descriptive names achieved in step 1 above using 'colnames' and 'rename' functions. 
## Further cleaning below:   

select_data <- as_tibble(select_data)                           #make data nicer to work with
names(select_data) <- sub("^V[0-9]+ ", "", names(select_data))  #remove "V## " from beginning of column names

## 5. From the data set in step 4, creates a second, independent tidy data set with the 
## average of each variable for each activity and each subject.

select_data_summary <- select_data %>%
        group_by(subjectID, activity) %>%
        summarize_all(list(mean = mean))
write.table(select_data_summary,"./run_analysis.txt", row.names = FALSE)