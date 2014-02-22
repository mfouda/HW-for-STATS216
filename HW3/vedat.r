#HW3 
#Q1)
#a)
load('body.RData')

boxplot(X$Shoulder.Girth ~ Y$Gender)
boxplot(Y$Height ~ Y$Gender)

# We can run couple of side by side boxplots. We expect men to be taller and have wider shoulders on average.
# Looking at these boxplots, we can infer that Gender=1 represents men.


#b)
library(pls)

# Let's combine Y$weight into X to create one combined data frame. It will make rest of the problem easier.
X <- cbind(Y$Weight,X)
colnames(X)[1]<-"Weight"

# It appears all male measurements at the top of our data, and all female at the bottom. Let's mix it up first.
set.seed(11)
X <- X[sample(nrow(X)),]

#Let's run pcr and plsr
X.training <- X[1:307,]
X.test <- X[308:507,]


set.seed(2)
pcr.fit=pcr(Weight ~ ., data=X.training, scale=TRUE,validation="CV")

set.seed(1)
pls.fit=plsr(Weight ~ ., data=X.training, scale=TRUE,validation="CV")

# Scaling makes sense because not all units of X features are on the same scale. 
# It is true that most features are in "cm"; however they still have different variance/characteristic (chest variance is different than wrist variance)

#c)
summary(pcr.fit)
summary(pls.fit)

# First few components explain most of the variance in the data. That's not surprisin to see.
# Marginal contribution of additional components after 4th or 5th component is not much, and it keeps getting smaller.

#d)
# We can plot the varieance explained by each component. We pick a value up to a point that we see a drop off.
# We think 2 or 4 is reasonable for PCR. We will go wtih 4.
# We think 3 is reasonable for PLS.

plot(explvar(pcr.fit), type="h")
plot(explvar(pls.fit), type="h")

#E) No, PLS and PCR use all 21 features. It created Principal components from them, but individual predictos are not necessarily dropped out of the model.
#We need a subset selction model for this purpose.
#We can use a best subset method given that we only have 21 parameters. Then apply, CV.
library(leaps)
regfit.full <- regsubsets(Weight ~ ., data=X.training,nvmax=21)
reg.summary <- summary(regfit.full)

par(mfrow =c(2,2))
plot(reg.summary$rss ,xlab=" Number of Variables ",ylab=" RSS",type="l")
plot(reg.summary$adjr2 ,xlab =" Number of Variables ",ylab=" Adjusted RSq",type="l")

which.max (reg.summary$adjr2)

# Adj R2 suggest selection of 15 variables
points (15, reg.summary$adjr2[15], col ="red",cex =2, pch =20)


#lets use cp and bic
plot(reg.summary$cp ,xlab =" Number of Variables ",ylab="Cp", type="l")
which.min (reg.summary$cp)

points (13, reg.summary$cp [13], col ="red",cex =2, pch =20)
which.min (reg.summary$bic )

plot(reg.summary$bic ,xlab=" Number of Variables ",ylab=" BIC",type="l")
points (11, reg.summary$bic[11], col ="red",cex=2, pch =20)

# Cp chose 13, and BIC chooses 11.

#Let's do CV. WE will only use training data.

predict.regsubsets =function (object ,newdata ,id ,...){
 form=as.formula (object$call [[2]])
 mat=model.matrix (form ,newdata )
 coefi =coef(object ,id=id)
 xvars =names (coefi )
 mat[,xvars ]%*% coefi
}


k=10
set.seed (1)

folds <- sample(1:k,nrow(X.training),replace =TRUE)
cv.errors =matrix (NA ,k,21, dimnames=list(NULL,paste(1:21)))

for(j in 1:k){
  best.fit <- regsubsets(Weight ~ . ,data=X.training[folds!=j,],nvmax =21)
  for(i in 1:21) {
    pred=predict(best.fit,X.training[folds==j,], id=i)
    cv.errors [j,i]=mean((X.training$Weight[folds==j]-pred)^2)
  }
}


mean.cv.errors =apply(cv.errors ,2, mean)
mean.cv.errors
which.min(mean.cv.errors)

par(mfrow =c(1,1))
plot(mean.cv.errors,type="b")

#Looking at CV with 10 folds we should use best subset with 15 predictors. Let's fit the full training set with two predictors to full set.
regfit.best <- regsubsets(Weight ~ ., data=X.training,nvmax=15)
reg.summary <- summary(regfit.best)
coef(regfit.best,15)

# So we actually need only 15 predictors according to best subset model and we can drop the other 6 predictors from the experiment.
predSubsetReg <- rep(0,200)
for(i in 1:200) {
    predSubsetReg[i] <- predict(regfit.best, X.test[i,],id=15)
}


library(pls)   # to use predict from this library

predPCR <- rep(0,200)
for(i in 1:200) {
    predPCR[i] <- predict(pcr.fit,X.test[i,],ncomp =4)
}


predPLS <- rep(0,200)
for(i in 1:200) {
    predPLS[i] <- predict(pls.fit,X.test[i,],ncomp =3)
}


pcr.MSE <- mean((predPCR - X.test$Weight)^2)
pls.MSE <- mean((predPLS - X.test$Weight)^2)
subsetReg.MSE <- mean((predSubsetReg - X.test$Weight)^2)
table(pcr.MSE,pls.MSE,subsetReg.MSE)

## Looking at test set MSE, the best model is best subset selection. It uses 15 predictors, and has a MSE of 7.098)
