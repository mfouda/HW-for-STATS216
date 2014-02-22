# Using all data/values/functions from in-class session

#Create new y response variable (binary home win=1/home loss=0)
y.wl <- with(games, ifelse(homeScore>awayScore,1,0))
#Logistic model using this new indicator (incl home adv & excl stanford & reg season games only)
homeAdv.mod.log <- glm(y.wl ~ 0 + homeAdv + ., data=X, subset=reg.season.games, family=binomial)
homeAdv.coef.log <- coef(homeAdv.mod.log)[paste("`",all.teams,"`",sep="")]
names(homeAdv.coef.log) <- all.teams
#Ranking accoring to logistic regression
homeAdv.coef.log[order(homeAdv.coef.log,decreasing=TRUE)[1:20]]
#look at the outliers (they only played 1 game each)
schedule("saint-mary-saint-mary","REG") #saint-mary's regular season schedule
schedule("st.-thomas-(tx)-celts","REG") #st.-thomas's regular season schedule

#Get index of games involving a team that played in less than 5 games.
gamelist=names(X[,which(colSums(abs(X),dims=1)<5)])
below5.teams.games <- which(
  games$away %in% gamelist |
  games$home %in% gamelist
)

#Remove all teams that played in less than 5 games and all games that those teams played in
X1 <- X[-below5.teams.games, -which(colSums(abs(X),dims=1)<5)] 
games2=games[-below5.teams.games,] #Remove games involving teams that played less than 5

#Refit logistic model
y.wl2 <- with(games2, ifelse(homeScore>awayScore,1,0)) #reset y response based fewer games
homeAdv2 <- 1 - games2$neutralLocation #reset HomeAdv based on fewer games
reg.season.games <- which(games2$gameType=="REG") #reset regular season index based on fewer games
homeAdv.mod.log <- glm(y.wl2 ~ 0 + homeAdv2 + ., data=X1, subset=reg.season.games, family=binomial)
homeAdv.coef.log <- coef(homeAdv.mod.log)[paste("`",teams$team,"`",sep="")]
names(homeAdv.coef.log) <- teams$team

#Refit linear model
y2 <- with(games2, homeScore-awayScore)
homeAdv.mod.ln <- lm(y2 ~ 0 + homeAdv2 + ., data=X1, subset=reg.season.games)
homeAdv.coef <- coef(homeAdv.mod.ln)[paste("`",teams$team,"`",sep="")]
names(homeAdv.coef) <- teams$team

#Compare Rankings
rank.table <- cbind("Model Score" = homeAdv.coef,
                    "Linear Model Rank"  = rank(-homeAdv.coef,ties="min"),
                    "Logistic Rank" = rank(-homeAdv.coef.log,ties="min"),
                    "AP Rank"     = teams$apRank,
                    "USAT Rank"   = teams$usaTodayRank)

rank.table[order(homeAdv.coef.log,decreasing=TRUE)[1:20],]

#Refit original linear regression with NEW data set(teams played > 5 games) 
#keeping the response y as the home margin spread
#y2 <- with(games2, homeScore-awayScore)
#homeAdv.mod.ln <- glm(y2 ~ 0 + homeAdv2 + ., data=X1, subset=reg.season.games)
(sum(summary(homeAdv.mod.ln)$coefficients[,4]<0.05)-1) / ncol(X1) #X1 does not contain homeAdv column

#Fraction of teams confident that p>0.05
#For logistic regression
#subtract 1 for the intercept which is homeAdv (which is significant)
(sum(summary(homeAdv.mod.log)$coefficients[,4]<0.05)-1) / ncol(X1)

#10-fold CV for each model
k=10
ntrain = nrow(X1)
foldid = rep(1:k, length = ntrain)
set.seed(1000)
foldid = sample(foldid)

#Include homeAdv(with fewer games) into the X variable matrix 
X2=data.frame(X1,homeAdv2)

#Initialize variables for calculating cv errors and storing contingency tables
cv.err.log=rep(0,10)
cv.err.ln=rep(0,10)
T=list()

for (i in 1:k) {
  #define test and training sets
  test = foldid==i
  train = foldid!=i
  #logistic model prediction
  homeAdv.mod.log <- glm(y.wl2 ~ 0 + homeAdv2 + ., data=X2, subset=train, family=binomial)
  homeAdv.log.probs <- predict(homeAdv.mod.log, newdata=data.frame(X2[test,]), type="response")
  homeAdv.log.pred = ifelse(homeAdv.log.probs>0.5,1,0)
  cv.err.log[i]=mean(homeAdv.log.pred!=y.wl2[test])
  #linear model prediction (if margin > 0 then predict a win)
  homeAdv.mod.ln <- lm(y2 ~ 0 + homeAdv2 + ., data=X2, subset=train)
  homeAdv.ln.margins <- predict(homeAdv.mod.ln, newdata=data.frame(X2[test,]))
  homeAdv.ln.pred = ifelse(homeAdv.ln.margins>0,1,0)
  cv.err.ln[i]=mean(homeAdv.ln.pred!=y.wl2[test])
  #Compare both predicted to actual and build contingency table for each fold
  #Store each contingency table into a list which can be summed later on for final table
  print(table(homeAdv.ln.pred==y.wl2[test],homeAdv.log.pred==y.wl2[test]))
  T[[i]] <- table(homeAdv.ln.pred==y.wl2[test],homeAdv.log.pred==y.wl2[test])
}

#Summary Contingency Table over all 10-fold CV
Contingentable = Reduce("+",T)
Contingentable
#Cross validation error rate for Logistic
mean(cv.err.log)
#Cross validation error rate for Linear
mean(cv.err.ln)

#McNemars Test 
#Matrix for D, n12, n21
D = Contingentable[1,2] + Contingentable[2,1]
#Confidence interval testing
low_end = D/2 - 2*sqrt(D)/2
high_end = D/2 + 2*sqrt(D)/2
#Low end of 95% confidence interval
low_end
#High end of 95% confidence interval
high_end
#n12
Contingentable[1,2]
#n21
Contingentable[2,1]


