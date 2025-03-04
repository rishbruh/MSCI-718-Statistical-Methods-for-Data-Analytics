## -----------------------------------------------------------------------------------------------------------------------------------------------------
#loading the required libraries
library(foreign)
library(caret)
library(haven)
library(dplyr)
library(glmnet)
library(stringr)


## -----------------------------------------------------------------------------------------------------------------------------------------------------

# we define our constants first
time_bw_arrival = 10  # this is the average time between patient arrivals
clinic_open_duration = 60*7  # Number of minutes for which the clinic is open (9am to 4pm,i.e.,7 hrs)
min_time_doc = 5  # minimum time patient spends with the doctor
time_doc_range = 15  # time range for patient treatment is from 5 to 20 minutes, i.e., 15mins

#runs = 1  # Number of runs of the simulation
runs = 1000 # switch between 1 and 1000 for achieving our simulation results for part a) and part b) respectively

#initializing empty vectors to store our data in
num_patient = c()  # the number of patients coming to the office
wait_time_patient = c()  # the number of patients having to wait
wait_time_avg = c()  # the average wait time for the patients
time_close = c()  # the closing time of the clinic

for (i in 1:runs){
#for running our simulation, we initialize the given variables to zero
    doctor_free = c(0, 0, 0) #initial vector for all 3 doctors being free
    arrival_time = 0 #initial arrival time is 0
    patients = 0 #initial number of patients is 0
    num_pats_wait = 0 #initial number of patients waiting is also 0
    total_wait_all = 0 #total wait time for all patients is initially 0
    
    while (TRUE){
        # Generate an arrival - but if they arrived after closing time,
        # terminate the sim and they're out of luck
        # Negative because we want the time to be positive
      
      #calculating the arrival times for our patients
        arrival_time = arrival_time - time_bw_arrival*log(runif(1))
        if (arrival_time > clinic_open_duration){   #we break the loop as patients can not enter after closing time
            break
        }
        patients = patients + 1
        #we now determine the time after which one of the three doctors becomes free
        doctor_free_next = min(doctor_free)
        #we calculate the waiting time of our patient by subtracting his wait time from the time a doctor becomes available
        time_wait = max(0, doctor_free_next-arrival_time)
        total_wait_all = total_wait_all + time_wait #total wait time for all our patients
      
        
    
        for (doc in 1:length(doctor_free)){
          
            if (doctor_free[doc] == doctor_free_next){
                doc_time = min_time_doc+runif(1)*time_doc_range #if one of our doctors is free we add our uniformly distributed time the doctor spends with the patient
                if (time_wait > 0){                            #case for when patient has to wait longer, we incrment the number of patients waiting, i.e., the num_pats_wait variable
                    num_pats_wait = num_pats_wait + 1
                    doctor_free[doc] = doctor_free_next+doc_time  #case when the doctor becomes free when his appoitnment ends
                }
                else{                                               
                    doctor_free[doc] = arrival_time+doc_time      
                    
                    break                                       #we break out the loop once our given patient is treated
                }
            }
        }
   
    }
    
    #we fill in our vectors with our results
    num_patient <- append(num_patient, patients)
    wait_time_patient<-append(wait_time_patient,num_pats_wait)
    wait_time_avg<-append(wait_time_avg,total_wait_all/patients)
    time_close<-append(time_close,max(doctor_free,clinic_open_duration))
}

#we create a fucntion which takes the median of our given data  
simulation_results <-function( title, data){
    # Sort the array into increasing order
    data <- sort(data)
     if (length(data)==1){
      print(paste(title,data))
    }
    else{
    median = data[length(data)/2]
    median = data[length(data)/2]
    print(paste(title,length(data),"runs is:", median))
  }
}

simulation_results("Number of patients in Clinic is", num_patient)
simulation_results("Number of patients having to wait is", wait_time_patient)
simulation_results("Average wait time for patients is", wait_time_avg)
simulation_results("Final closing time for the clinic is", time_close)



## -----------------------------------------------------------------------------------------------------------------------------------------------------

#a)

#reading the input data files
data1 <- read.dta('Q1Data1.dta')
data2 <- read.csv('Q1Data2.csv', header = TRUE)

#displaying our dataframe 
head(data1)

#selecting columns of state, marital, heat2 and heat4 from our dataset using the subset function
data1 <- subset(data1, select = c(state,marital,heat2,heat4))

head(data1)

#dropping all rows for the state of Hawaii, Alaska and Washington DC using the subset function
data1 <- subset(data1, state!="hawaii" & state!="alaska" & state!="washington dc")

#using as.character to generate string representation for our heat2 and heat4 columns
data1$heat2 <- as.character(data1$heat2)
data1$heat4 <- as.character(data1$heat4)

#replacing every NA value in heat2 with its corresponding value in heat4
for(i in 1:nrow(data1)){
 
  if(is.na(data1$heat2[i]))
    data1$heat2[i]<-data1$heat4[i]
}

#dropping all rows with NA in our heat2 column
data1 <- data1[!is.na(data1$heat2),]
data1$heat2 <- as.factor(data1$heat2)
data1$heat4 <- as.factor(data1$heat4)


#data1 <- subset(data1, heat2 !="dem/lean dem" & heat2 !="rep/lean rep”)

#Subsetting our data frame data1 to only have “dem/lean dem” and “rep/lean rep” in the heat2 column.
data1 <- subset(data1, heat2 !="other-dk" 
                  & heat2 !="3rd party/lean 3rd party (barr)"
                  & heat2 !="4th party/lean 4th party (nader)")


#changing the labels in the marital column of all variables apart from "married" to "other", using the str_replace_all function
data1$marital <- str_replace_all(data1$marital,"widowed","other")
data1$marital <- str_replace_all(data1$marital,"never married","other")
data1$marital <- str_replace_all(data1$marital,"living with a partner","other")
data1$marital <- str_replace_all(data1$marital,"divorced","other")
data1$marital <- str_replace_all(data1$marital,"separated","other")
data1$marital <- str_replace_all(data1$marital,"dk/refused","other")

#dropping all NA values in marital column
data1_final <- data1[!is.na(data1$marital),]

#displaying the first 5 entries of our final dataset (data1_final)
head(data1_final,5)



######################################################################################################################################################

# b)

#1.Calculating the proportion of the democratic supporters,

#using the dplyr library to implement the select(), group_by(), filetr() and count() functions

#grouping data by state for the state and heat2 columns
group_states <- data1_final %>% select(state,heat2) %>% group_by(state) 

#finding total votes from each state
total_votes_by_states <- group_states %>% count(state)

total_votes_by_states

#calculating the total democrat leaning voters from each state
total_democrats <- data1_final %>% select(state,heat2) %>% group_by(state) %>% filter(heat2=="dem/lean dem") %>% count(heat2)

#converting the "n" column values to double datatype to avoid double precision error
total_democrats$n <- as.double(total_democrats$n)

#finding proportion of the total democrat supporters to the total voters for each state and calculating its percentage (i.e., calculating percentage of democrat voters for each state) 
for (i in 1:length(total_democrats[[2]])){
  total_democrats[3][i,] <- (total_democrats[3][i,]/total_votes_by_states[2][i,])*100
}

proportion_democratic <- total_democrats

#renamimg the column "n" to democrat_percent (which is the percentage of democrat supporters for each state)
proportion_democratic <- proportion_democratic %>% rename(democrat_percent = n)

#displaying first 5 observations of our dataframe
head(proportion_democratic,5)




#2 Calculating the proportion of the married people

#finding the count of total married people for each state
total_married <- data1_final %>% select(state,marital) %>% group_by(state) %>% filter(marital=="married") %>% count(marital)

#converting the "n" column values to double datatype to avoid double precision error
total_married$n <- as.double(total_married$n)

#finding proportion of total married people to the total voters for each state and calculating its percentage (i.e., calculating percentage of married voters for each state) 
for (i in 1:length(total_married[[2]])){
  total_married[3][i,] <- (total_married[3][i,]/total_votes_by_states[2][i,])*100
}

proportion_married <- total_married

#renamimg the column "n" to married_percent (which is the percentage of married voters for each state)
proportion_married <- proportion_married %>% rename(married_percent = n)

#displaying first 5 observations of our dataframe
head(proportion_married,5)




#3 Calculating the ratio of the married people among the democratic supporters to the total married people

#finding the count of total married democratic supporters for each state
married_dem <- data1_final %>% select(heat2,state,marital) %>% group_by(state) %>% filter(heat2=="dem/lean dem" & marital=="married") %>% count(marital)

married_total <- data1_final %>% select(state,marital) %>% group_by(state) %>% filter(marital=="married") %>% count(marital)

#converting the "n" column values to double datatype to avoid double precision error
married_dem$n <- as.double(married_dem$n)

#finding proportion of the married democratic supporters to the total married voters and calcualting its percentage (i.e., calculating percentage of married democratic voters for each state amongst the total married voters )
for (i in 1:length(married_dem[[2]])){
  married_dem[3][i,] <- (married_dem[3][i,]/married_total[3][i,])*100
}

proportion_married_dem<-married_dem

#renamimg the column "n" to married_dem_percent (which is the percentage of married democratic voters for each state)
proportion_married_dem <- proportion_married_dem %>% rename(married_dem_percent = n)


#displaying first 5 observations of our dataframe
head(proportion_married_dem,5)



#4 Calculating the ratio of non-married among the democratic to the total non-married people

#finding the count of total non-married voters for each state
total_non_married <- data1_final %>% select(state,marital) %>% group_by(state) %>% filter(marital=="other") %>% count(marital)

#finding the count of total non-married democratic supporters for each state
non_married_dem <- data1_final %>% select(heat2,state,marital) %>% group_by(state) %>% filter(heat2=="dem/lean dem" & marital=="other") %>% count(marital)

#converting the "n" column values to double datatype to avoid double precision error
non_married_dem$n <- as.double(non_married_dem$n)
total_non_married$n <- as.double(total_non_married$n)

#finding the ratio of the non-married democratic supporters to the total non-married voters and calculating its percentage (i.e., calculating percentage of non-married democratic voters for each state amongst the total non-married voters.
for (i in 1:length(non_married_dem[[2]])){
  non_married_dem[3][i,] <- (non_married_dem[3][i,]/total_non_married[3][i,])*100
}

proportion_non_married_dem<-non_married_dem

#renamimg the column "n" to non_married_dem_percent (which is the percentage of non-married democratic voters for each state)
proportion_non_married_dem <- proportion_non_married_dem %>% rename(non_married_dem_percent = n)

#displaying first 5 observations of our dataframe
head(proportion_non_married_dem,5)



#5 Finding the difference between proportion of married democratic supporters and proportion of non-married democratic supporters

diff<-c()
for(i in 1:length(proportion_non_married_dem[[3]])){
  diff[i] <- proportion_married_dem[[3]][i] - proportion_non_married_dem[[3]][i]
}

#creating new dataframe to store our calcualated values
difference_bw_marital<-data.frame(proportion_non_married_dem$state,diff)

#displaying first 5 observations of our dataframe
head(difference_bw_marital,5)

######################################################################################################################################################

# c)

#Subsetting our data frame data2 to drop observations for the states of Hawaii, Alaska and DC
data2<-subset(data2,state != "Hawaii" & state != "Alaska" & state!="District of Columbia")

#Dropping all columns apart from vote_Obama_pct which gives Obama's vote percentage share
data2_final<-subset(data2,select=c(state,vote_Obama_pct))

#displaying first 5 observations of our dataframe
head(data2_final,5)



## -----------------------------------------------------------------------------------------------------------------------------------------------------
# d)

#creating a dataframe to store our predictor variables - State, Marital, Percentage of democratic supporters, Percentage of married voters and the difference between married and non-married democratic supporters

model_dataframe <- data.frame(proportion_democratic$state,
                        proportion_democratic$democrat_percent,
                        proportion_married$married_percent,proportion_married$marital, difference_bw_marital$diff)


#For predicting voting intention of each state with marriage as an indicator, we set up our model_predictor and model_outcome dataframes

#Our model_predictor has our predcitor variables of percentage of married voters and the state
model_predictor <- model.matrix(proportion_democratic$democrat_percent ~ proportion_married.married_percent + proportion_democratic.state, data = model_dataframe)

#our model outcome is the voting intention which we find from the percentage of democratic supporters
model_outcome <- model_dataframe$proportion_democratic.democrat_percent



#Assumption 1: No state-level heterogeneity. All states have the same intercept and slope.

#This assumption of having no state-level heterogeneity implies performing a pooled regression. This complete pooling assumes that there is zero variance between our predictor subgroups

#the glmt package is used for generating our full pooling modee and lambda is set to a very high value to penalize our coeffecients.
model_full_pooling <- glmnet(x=model_predictor ,y= model_outcome,alpha=0,lambda=10^5)

#gives the model summary
model_full_pooling

#displays the model's coefficients
coef(model_full_pooling)



#Assumption 2: Complete state-level heterogeneity. All states have completely independent intercepts and slopes. No outlying coefficient is penalized.

#This assumption of having complete state-level heterogeneity implies performing a dummy variable regression. This no pooling assumes that there is infinite variance between our individual predictor subgroups

#the glmt package is used for generating our no pooling model and lambda is set to 0 to not penalize our coefficients
model_no_pooling <- glmnet(x=model_predictor ,y= model_outcome,alpha=0,lambda=0)

#gives the model summary
model_no_pooling

#displays the model's coefficients
coef(model_no_pooling)



#Assumption 3: State-level heterogeneity is unknown a priori. States have partially pooled intercepts and slopes. Outlying coefficients are penalized.

#This assumption implies performing partial pooling regression. In this the group-level variation is also accounted for.

#we first perform cross validation to obtain the best lambda value for our model
model_partial_pooling<- cv.glmnet(model_predictor,model_outcome,alpha=0)

best_lambda<-model_partial_pooling$lambda.min

#the glmt package is used for generating our partial pooling model and lambda is set to the value of the best lambda we find from the cross validation method
model_partial_final<-glmnet(x=model_predictor,y=model_outcome,alpha=0,lambda = best_lambda)

#gives the model summary
model_partial_final

#displays the model's coefficients
coef(model_partial_final)

######################################################################################################################################################

# e)

#predicting the vote intention with the assumption 3 model (i.e., the partial pooling model)
y_predict<-predict(model_partial_final,s= best_lambda,newx = model_predictor)

#displays out predicted values
y_predict

#using the plot() function to generate a plot for the predicted vote share by state, along with the actual vote intention vs. Obama’s actual vote share.
plot(data2_final$vote_Obama_pct,y_predict,col = "red")
par(new=T)
plot(data2_final$vote_Obama_pct,model_outcome,col="forestgreen")

#annotating the data points with their respective state names
text(data2_final$vote_Obama_pct,model_outcome, 
     labels = model_dataframe$proportion_democratic.state, cex=0.5,pos=3,col="navyblue") 

######################################################################################################################################################

# f)
#predicting the marriage gap(given under the "diff" column of the difference_bw_marital dataframe) vote share using the percentage of married individuals, percentage of democrat supporters and the state.we set up our model_predictor_gap and model_outcome_gap accordingly

model_predictor_gap <- model.matrix(difference_bw_marital$diff ~ proportion_democratic$democrat_percent + proportion_married.married_percent + proportion_democratic.state, data = model_dataframe)

model_outcome_gap <- model_dataframe$difference_bw_marital.diff

#using the model assumption 3, i.e., partial pooling to estimate our results

#we first perform cross validation to obtain the best lambda value for our model
model_partial_pooling_gap<- cv.glmnet(model_predictor_gap,model_outcome_gap,alpha=0)

best_lambda_gap<-model_partial_pooling_gap$lambda.min

#the glmt package is used for generating our partial pooling model and lambda is set to the value of the best lambda we find from the cross validation method
model_partial_final_gap<-glmnet(x=model_predictor_gap,y=model_outcome_gap,alpha=0,lambda = best_lambda_gap)

#gives the model summary
model_partial_final_gap

#displays the model's coefficients
coef(model_partial_final_gap)

##predicting the marriage gap with the assumption 3 model (i.e., the partial pooling model)
y_predict_gap<-predict(model_partial_final_gap,newx = model_predictor_gap)

#displays out predicted values
y_predict_gap

#using the plot() function to generate a plot for the predicted marriage gap by state, along with the raw marriage gaps which are provided by our model_outcome_gap.This is plotted with respect to Obama’s actual vote share.
plot(data2_final$vote_Obama_pct,y_predict_gap,col = "red")
par(new=T)
plot(data2_final$vote_Obama_pct,model_outcome_gap,col="forestgreen")

#annotating the data points with their respective state names
text(data2_final$vote_Obama_pct,model_outcome_gap, 
     labels = model_dataframe$proportion_democratic.state, cex=0.5,pos=3,col="navyblue")

######################################################################################################################################################

# g)

#predicting the vote intention with the assumption 2 model (i.e., the no-pooling model)
y_predict<-predict(model_no_pooling,newx = model_predictor)

#displays out predicted values
y_predict

#using the plot() function to generate a plot for the predicted vote share by state, along with the actual vote intention vs. Obama’s actual vote share.
plot(data2_final$vote_Obama_pct,y_predict,col = "red")
par(new=T)
plot(data2_final$vote_Obama_pct,model_outcome,col="forestgreen")

#annotating the data points with their respective state names
text(data2_final$vote_Obama_pct,model_outcome, 
     labels = model_dataframe$proportion_democratic.state, cex=0.5,pos=3,col="navyblue") 


#using the model assumption 2, i.e., partial pooling to estimate our results

#the glmt package is used for generating our no pooling model and lambda is set to 0 to not penalize our coefficients
model_no_pooling_gap <- glmnet(x=model_predictor_gap ,y= model_outcome_gap,alpha=0,lambda=0)

#gives the model summary
model_no_pooling_gap

#displays the model's coefficients
coef(model_no_pooling_gap)

##predicting the marriage gap with the assumption 2 model (i.e., the no-pooling model)
y_predict_gap<-predict(model_no_pooling_gap,newx = model_predictor_gap)

#displays out predicted values
y_predict_gap

#using the plot() function to generate a plot for the predicted marriage gap by state, along with the raw marriage gaps which are provided by our model_outcome_gap.This is plotted with respect to Obama’s actual vote share.
plot(data2_final$vote_Obama_pct,y_predict_gap,col = "red")
par(new=T)
plot(data2_final$vote_Obama_pct,model_outcome_gap,col="forestgreen")

#annotating the data points with their respective state names
text(data2_final$vote_Obama_pct,model_outcome_gap, 
     labels = model_dataframe$proportion_democratic.state, cex=0.5,pos=3,col="navyblue")


######################################################################################################################################################



## -----------------------------------------------------------------------------------------------------------------------------------------------------




