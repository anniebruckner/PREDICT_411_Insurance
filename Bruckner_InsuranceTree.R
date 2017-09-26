# Insurance Decision Tree
# References: 
# http://discuss.analyticsvidhya.com/t/what-are-the-packages-required-to-plot-a-fancy-rpart
# -plot-in-r/6776
# # http://www.r-bloggers.com/in-depth-introduction-to-machine-learning-in-15-hours-of-
# expert-videos/

install.packages("rpart")
install.packages("rpart.plot")
install.packages("RGtk2")
install.packages("rattle")
install.packages("RColorBrewer")
library(rpart)
library(rpart.plot)
library(RGtk2)
library(rattle)
library(RColorBrewer)
#options(scipen = 999)

# Read in file.
insurance <- read.csv(file.path("/Users/annie/Desktop/Northwestern/PREDICT_411/Unit02/Insurance","bruckner_model2a.csv"),sep=",")

# When you run the str() command it shows you what type of variable each in your data set is.
# When I run this, I notice that HOMEVAL, bluebook, Revoked and others are read in as "factor" this means that
# Each value is seen as a category vs. a continuous variable. This is obviously no good and
# will throw off most if not all of your analysis. 

str(insurance)

InsuranceTreeIMP <- rpart(TARGET_FLAG ~ 
                         IMP_AGE	+
                         IMP_BLUEBOOK	+
                         IMP_CAR_AGE	+
                         CAR_TYPE	+
                         CAR_USE	+
                         CLM_FREQ	+
                         EDUCATION	+
                         HOMEKIDS	+
                         IMP_HOME_VAL	+
                         IMP_INCOME	+
                         IMP_JOB	+
                         KIDSDRIV	+
                         MSTATUS	+
                         MVR_PTS	+
                         OLDCLAIM	+
                         PARENT1	+
                         RED_CAR	+
                         REVOKED	+
                         SEX	+
                         TIF	+
                         IMP_TRAVTIME	+
                         URBANICITY +
                         IMP_YOJ, data = insurance)

# Removing the incorrectly classified 'Factor' variables 
InsuranceTreeIMP <- rpart(TARGET_FLAG ~ 
                            IMP_AGE	+
                            #IMP_BLUEBOOK	+
                            IMP_CAR_AGE	+
                            CAR_TYPE	+
                            CAR_USE	+
                            CLM_FREQ	+
                            EDUCATION	+
                            HOMEKIDS	+
                            IMP_HOME_VAL	+
                            IMP_INCOME	+
                            IMP_JOB	+
                            KIDSDRIV	+
                            MSTATUS	+
                            MVR_PTS	+
                            #OLDCLAIM	+
                            PARENT1	+
                            RED_CAR	+
                            REVOKED	+
                            SEX	+
                            TIF	+
                            IMP_TRAVTIME	+
                            URBANICITY +
                            IMP_YOJ, data = insurance, method='class')

InsuranceTreeIMP
plot(InsuranceTreeIMP)
text(InsuranceTreeIMP)

summary(InsuranceTreeIMP)

rpart.plot(InsuranceTreeIMP)

fancyRpartPlot(InsuranceTreeIMP)

# ------------------------------------------------------------------
# Fixing the incorrectly classified 'Factor' varialbes to 'numeric'
#insurance$bluebook_n <- as.numeric(insurance$BLUEBOOK)
insurance$OLDCLAIM_n <- as.numeric(insurance$OLDCLAIM)

# Confirm that the updates have worked
str(insurance)

# Run New Tree
InsuranceTreeIMP.2 <- rpart(TARGET_FLAG ~ 
                            IMP_AGE	+
                            IMP_BLUEBOOK	+
                            IMP_CAR_AGE	+
                            CAR_TYPE	+
                            CAR_USE	+
                            CLM_FREQ	+
                            EDUCATION	+
                            HOMEKIDS	+
                            IMP_HOME_VAL	+
                            IMP_INCOME	+
                            IMP_JOB	+
                            KIDSDRIV	+
                            MSTATUS	+
                            MVR_PTS	+
                            OLDCLAIM_n	+
                            PARENT1	+
                            RED_CAR	+
                            REVOKED	+
                            SEX	+
                            TIF	+
                            TRAVTIME	+
                            URBANICITY +
                            IMP_YOJ, data = insurance, method='class')

# Summary Stuff and a decent plot
InsuranceTreeIMP.2 # Gives rules at each cutpoint and the accuracy of prediction at each node.

plot(InsuranceTreeIMP.2, uniform=TRUE, 
     main="Classification Tree for Insurance")
text(InsuranceTreeIMP.2, use.n=TRUE, all=TRUE, cex=.8)

#rpart.plot(InsuranceTreeIMP.2)
fancyRpartPlot(InsuranceTreeIMP.2, uniform = TRUE)
