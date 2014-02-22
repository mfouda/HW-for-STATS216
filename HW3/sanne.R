h <- function(x, z){
  if (x>z) {
    return((x-z)^3)
  } else {
    return(0)
  }
}

hs <- function(xs, zs){
  return(sapply(xs, function(x) h(x, zs)))
}

splinebasis <- function(xs, zs){
  sb=matrix(rep(NA, (length(xs)*(length(zs)+3))), nrow=length(xs), ncol=(length(zs)+3))
  sb[, 1]=xs
  sb[, 2]=xs^2
  sb[, 3]=xs^3
  for(i in 1:length(zs)){
    sb[,i+3]=hs(xs, zs[i])
  }
  return(sb)
}

set.seed(1337)
x = runif(100)
y = sin(10*x)

knots = c(1/4,2/4,3/4)
splines=splinebasis(x, knots)
data<-data.frame(y, splines)
lm.fit<-lm(y~., data=data)

fx=seq(0, 1, len=101)
fy=sin(10*fx)
plot(fx, fy, type="l", col="blue", lwd=2)
points(x, y)

tsplines=splinebasis(fx, knots)
tdata<-data.frame(y=rep(0,101), tsplines)
tdata$y<-predict(lm.fit, newdata=tdata)
lines(fx, tdata$y, type="l", col="red", lwd=2)

for (k in 1:9){
  plot(fx, fy, type="l", col="blue", lwd=2, main=paste(k, "knots"))
  knots=1:k/(k+1)
  splines=splinebasis(x, knots)
  data<-data.frame(y, splines)
  lm.fit=lm(y~., data=data)
  tsplines=splinebasis(fx, knots)
  tdata<-data.frame(y=rep(0,101), tsplines)
  tdata$y<-predict(lm.fit, newdata=tdata)
  lines(fx, tdata$y, type="l", col="red", lwd=2)
}


