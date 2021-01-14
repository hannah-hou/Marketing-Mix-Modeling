# set work directory
setwd('/Users/hannahhou/Desktop/MMM/model work')

#read data
AF = read.csv(file='AF_Final.csv', header=TRUE)
#colnames(AF)[1] = 'Period'

#update period column
AF$Period = as.Date(AF$Period, "%m/%d/%Y")

#Black Friday
AF[,'Black_Friday'] = 0
AF[which(AF$Period=='2014-11-24'),'Black_Friday']=1
AF[which(AF$Period=='2015-11-30'),'Black_Friday']=1
AF[which(AF$Period=='2016-11-28'),'Black_Friday']=1
AF[which(AF$Period=='2017-11-27'),'Black_Friday']=1
sum(AF[,'Black_Friday'])

#July 4th
AF[,'July_4th'] = 0
AF[which(AF[,'Period']=='2014-07-07'),'July_4th']=1
AF[which(AF$Period=='2015-07-06'),'July_4th']=1
AF[which(AF$Period=='2016-07-04'),'July_4th']=1
AF[which(AF$Period=='2017-07-03'),'July_4th']=1
sum(AF[,'July_4th'])
#some small grammar in R
sum(AF$July_4th)
AF[1,1]
AF[1,'July_4th']
AF[,'July_4th']

#draw plot for sales event
plot(AF$Period,AF$Sales,type='l',xlab='Period',ylab='Sales')
par(new=TRUE)
plot(AF$Period,AF$Sales.Event,type='l',xlab='',ylab='',axes=FALSE,col='green')
axis(side=4)
#draw plot for holiday1
plot(AF$Period,AF$Sales,type='l',xlab='Period',ylab='Sales')
par(new=TRUE)
plot(AF$Period,AF$Black_Friday,type='l',xlab='',ylab='',axes=FALSE,col='green')
axis(side=4)
#draw plot for holiday2
plot(AF$Period,AF$Sales,type='l',xlab='Period',ylab='Sales')
par(new=TRUE)
plot(AF$Period,AF$July_4th,type='l',xlab='',ylab='',axes=FALSE,col='green')
axis(side=4)


#Build Model
#step1:  baseline variables
model1 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event)
summary(model1)

#step2: add media
#add TV
#model2 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV1) 
#summary(model2)
model2 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2) 
summary(model2)

#add search
model3 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2+PaidSearch1) 
summary(model3)

#add wechat
model4 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2+PaidSearch1+Wechat2) 
summary(model4)

#add magazine
model5 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2+PaidSearch1+Wechat2+Magazine1) 
summary(model5)

#add Display
model6 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2+PaidSearch1+Wechat2+Magazine1+Display2)
summary(model6)

#add Facebook
model7 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2+PaidSearch1+Wechat2+Magazine1+Display2+Facebook1) 
summary(model7)

#add competitor spend
model8 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2+PaidSearch1+Wechat2+Magazine1+Display2+Facebook1+Comp.Media.Spend) 
summary(model8)

#Export Results
model8 = lm(data=AF, Sales~July_4th+Black_Friday+CCI+Sales.Event+NationalTV2+PaidSearch1+Wechat2+Magazine1+Display2+Facebook1+Comp.Media.Spend, x=TRUE) 
View(model8$x)
model8$coefficients

#calculate contribution
contribution = sweep(model8$x,2,model8$coefficients, "*")

contribution = data.frame(contribution)
contribution$Period=AF$Period
#contribution[,'Period'] = AF[,'Period']
names(model8$coefficients)
colnames(contribution) = c(names(model8$coefficients), 'Period')
#c is combine

#transform contribution into flat format
install.packages('reshape')
library('reshape')
contri= melt(contribution, id.vars='Period')
write.csv(contri, file='contribution.csv', row.names=FALSE)

#AVM
AVM = cbind(AF[,c('Period', 'Sales')], model8$fitted.values)
colnames(AVM)  = c('Period', 'Sales', 'Predicted Sales')
write.csv(AVM, file='AVM.csv', row.names = FALSE)

#calculate MAPE
AVM$MAPE = abs(AVM$Sales-AVM$`Predicted Sales`)/AVM$Sales
mean(AVM$MAPE)
