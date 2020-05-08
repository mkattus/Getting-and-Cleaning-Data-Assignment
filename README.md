# Getting-and-Cleaning-Data-Assignment

This ReadMe explains how the script works and how each section is connected.

In this assignment, we were given raw data from the UCI HAR Dataset and asked to generate a tidy data set with the average of each mean variable for each activity and each subject. My script 'run_analysis.R' achieves just that. See script with explanations below. Data file can be read into R with read.table(header = TRUE).

## Load packages to be used in script

I used the dplyr package because it streamlines data manipulation. I used the tibble package because it presents data in a clean format that makes it easier to understand, and, therefore, operate on.

```
library(dplyr)
library(tibble)
```

## 0. Read in data
Per directions, this code will run "as long as the Samsung data is in your working directory." Must have data set loaded in working directory for script to run! Samsung data found here: https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 

Each file assigned to readable and intuitive names to make later manipulation easy.

```
x_test <- read.table("./UCI HAR Dataset/test/X_test.txt")
y_test <- read.table("./UCI Har Dataset/test/y_test.txt")
subject_test <- read.table("./UCI HAR Dataset/test/subject_test.txt")
x_train <- read.table("./UCI HAR Dataset/train/X_train.txt")
y_train <- read.table("./UCI HAR Dataset/train/y_train.txt") 
subject_train <- read.table("./UCI HAR Dataset/train/subject_train.txt")
activities <- read.table("./UCI HAR Dataset/activity_labels.txt")
variables <- read.table("./UCI HAR Dataset/features.txt")
activity_labels <- read.table("./UCI HAR Dataset/activity_labels.txt", stringsAsFactors = FALSE)
```

## 1. Create one data set
The goal here is to make a single, tidy data set comprised raw data read in above. I first merged the 'test' data (subject IDs, activities, and measurements), as well as assigned names to the variable to make later merging easy. Then I merged the 'training' data, along with the same names used above. Creating the test and training data sets to have the same variable names make merging these two data sets really easy with the 'rbind' function. It also took care of step 4 below. 

Single merged data set is called: 'data'

```
colnames(x_test) <- paste(colnames(x_test), variables$V2)       #merge and rename test data 
y_test <- rename(y_test, activity = V1)
subject_test <- rename(subject_test, subjectID = V1)
test_data <- cbind(subject_test, y_test, x_test)

colnames(x_train) <- paste(colnames(x_train), variables$V2)     #merge and rename train data
y_train <- rename(y_train, activity = V1)       
subject_train <- rename(subject_train, subjectID = V1)
train_data <- cbind(subject_train, y_train, x_train)

data <- rbind(test_data, train_data)                            #merge test and train data
```


## 2. Extract only the measurements on the mean and standard deviation for each measurement
By reading the 'features_info.txt' included in the raw data set, you can deduce that measurements on the mean and standard deviation for the measurements included "mean" "Mean" "std" or "Std" in their name. I used the 'grep' function along with normal expressions to find the variable names that include those patterns, then used to 'select' function (dplyr package) to extract data that met the requirements. The extracted data set is called 'select_data' and only includes the measurements on the mean and standard deviation for each measurement, and preserves participant ID and activity.

```
select_cols <- grep(("[Mm]ean|[Ss]td"), colnames(data), value = TRUE)
select_data <- select(data, subjectID, activity, all_of(select_cols))
```

## 3. Use descriptive activity names to name the activities in the data set
Activities in the raw data are denoted by numbers that are associated with an activity. That association is found in the file 'activity_labels.txt' in the raw data where each number 1:6 is associated with a descriptive activity name ("laying", "walking", etc.). I used a for loop to cycle through the 'activity' column in 'select_data' and replace each number with its associated descriptive activity name.

```
for(i in seq_along(activity_labels$V2)){
        select_data$activity <- sub(activity_labels$V1[i], activity_labels$V2[i], select_data$activity)
}
```

## 4. Appropriately label the data set with descriptive variable names
Descriptive names achieved in step 1 above using 'colnames' and 'rename' functions. The variable are named according to the conventions layed out in the Code Book (see repository). Variable names are found in 'features.txt' from raw data. They are descriptive because they include the signal origin (acc = accelerometer or gyro = gyroscope), direction component (X,Y,Z), time domain signal vs. frequency domain signal (t vs. f), body and gravity acceleration signals (BodyAcc vs. GravityAcc), jerk signals (Jerk), and magnitudes (Mag). Further cleaning to make easier to read below:   

```
select_data <- as_tibble(select_data)                           #make data nicer to work with
names(select_data) <- sub("^V[0-9]+ ", "", names(select_data))  #remove "V## " from beginning of column names
names(select_data) <- gsub("-", "", names(select_data))         #remove "-"
names(select_data) <- sub("std", "Std", names(select_data))     #make STD stand out
names(select_data) <- sub("mean", "Mean", names(select_data))   #make Mean stand out
names(select_data) <- gsub("\\()", "", names(select_data))      #remove "()"
```

## 5. Create a second, independent tidy data set with the average of each variable for each activity and each subject
'dplyr' makes this very easy. I simply grouped the 'select_data' set by 'activity' and 'subjectID' then created a summary of all variable based on the mean function. The output values are means of each variable (both the means and standard deviations), so I inserted "-mean" to the end of each variable name. The data set is tidy because: 1) Each variable forms a column. 2) Each observation forms a row. 3) Each type of observational unit forms a table (there is only one type of observational unit, therefore there is only one table). (source: Hadley Wickham's **Tidy data.** https://vita.had.co.nz/papers/tidy-data.html) Output is a data set as a txt file created with write.table() using row.name=FALSE per instructions. 

```
select_data_summary <- select_data %>%
        group_by(subjectID, activity) %>%
        summarize_all(list(mean = mean))
write.table(select_data_summary,"./run_analysis.txt", row.names = FALSE)
```