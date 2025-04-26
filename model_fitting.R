# -- head -- #

setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(glue)
library(lme4)
library(broom.mixed)
library(performance)

# -- src -- #

source('helper.R')
# coercion shmoercion

# -- young -- #

## vocabulary size

idsy |> ggplot(aes(s_size,s_age)) + 
  geom_point() +
  geom_smooth()

myv1 = lm(s_size ~ s_age, data = idsy)
myv2 = lm(s_size ~ poly(s_age,2,raw=TRUE), data = idsy)
myv3 = lm(s_size ~ poly(s_age,3,raw=TRUE), data = idsy)
compare_performance(myv1,myv2,myv3,metrics = 'common')
anova(myv1,myv2)
anova(myv1,myv3)
# myv1

## standard models

mys1 = lmer(resp.rt ~ 1 + s_age + s_word + s_size + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mys2 = lmer(resp.rt ~ 1 + s_age * s_word + s_size + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mys3 = lmer(resp.rt ~ 1 + s_age + s_size * s_word + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

compare_performance(mys1,mys2,mys3,metrics = 'common')
check_collinearity(mys1)
check_collinearity(mys2)
check_collinearity(mys3)
test_likelihoodratio(mys1,mys2)
test_likelihoodratio(mys1,mys3)
# mys1

## residuals

myr1 = lmer(resp.rt ~ 1 + s_age + res_size_age + s_word + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
myr2 = lmer(resp.rt ~ 1 + s_age * res_size_age + s_word + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
# myr1

# -- old -- #

## vocabulary size

gam_old = mgcv::gam(s_size ~ s(s_edu) + s(s_age), data = idso)
plot(gam_old)
mov1 = lm(s_size ~ 1 + s_edu + s_age, data = idso)
mov2 = lm(s_size ~ 1 + s_edu + poly(s_age, 3, raw=TRUE), data = idso)
mov3 = lm(s_size ~ 1 + poly(s_edu, 2, raw=TRUE) + s_age, data = idso)
mov4 = lm(s_size ~ 1 + poly(s_edu, 2, raw=TRUE) + poly(s_age, 3, raw=TRUE), data = idso)
mov5 = lm(s_size ~ 1 + poly(s_edu, 2, raw=TRUE) + poly(s_age, 2, raw=TRUE), data = idso)
mov6 = lm(s_size ~ 1 + s_edu + poly(s_age, 2, raw=TRUE), data = idso)
mov7 = lm(s_size ~ 1 + poly(s_edu, 3, raw=TRUE) + poly(s_age, 2, raw=TRUE), data = idso)
compare_performance(mov1,mov2,mov3,mov4,mov5,mov6,mov7, metrics = 'common') |> arrange(-AIC,-BIC)
tidi(mov6)
tidi(mov2)
anova(mov1,mov2)
anova(mov1,mov6)
# mov1

## standard model

# base model
fit11 = lmer(resp.rt ~ 1 + s_age + s_word + s_size + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit12 = lmer(resp.rt ~ 1 + s_age * s_word + s_size + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit13 = lmer(resp.rt ~ 1 + s_age + s_size * s_word + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

compare_performance(fit11,fit12,fit13,metrics = 'common')

plot_model(fit11, 'est') +
  theme_bw() +
  geom_hline(yintercept = 0, lty = 2)
plot_model(fit11, 'pred', terms = c('s_age'))
check_collinearity(fit11)
tidi(fit11)

# -- model: old -- #

# base model
mos1 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

# 2-way interactions
mos2 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mos3 = lmer(resp.rt ~ 1 + s_age + s_edu * s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mos4 = lmer(resp.rt ~ 1 + s_age + s_edu + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

# bad 2-way interactions
mos1b = lmer(resp.rt ~ 1 + s_age * s_edu + s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mos1c = lmer(resp.rt ~ 1 + s_age * s_size + s_edu + s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mos1d = lmer(resp.rt ~ 1 + s_age + s_size * s_edu + s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

check_collinearity(mos1b)
check_collinearity(mos1c)
check_collinearity(mos1d)

# 3-way interactions
mos5 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu * s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mos6 = lmer(resp.rt ~ 1 + s_age + s_edu * s_word + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mos7 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mos8 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu * s_word + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

perf_table_old = compare_performance(mos1,mos2,mos3,mos4,mos5,mos6,mos7,mos8, metrics = 'common')
arrange(perf_table_old,-AIC) 
arrange(perf_table_old,-BIC) 

anova(mos3,mos1)
# mos1, I won't include a spurious unforeseen interaction based on p = .046

## residuals

mor1 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + res_size_age + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mor2 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + res_size_edu + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000))) # these two are the same lol
mor3 = lmer(resp.rt ~ 1 + s_edu + s_word + res_size_age * s_age + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mor4 = lmer(resp.rt ~ 1 + s_age + s_word + res_size_edu * s_edu + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

# mor1 == mor2
compare_performance(mor1,mor3,mor4, metrics = 'common')
anova(mor1,mor3)
anova(mor1,mor4)
# mor3, mor4

# -- both! -- #

comb1 = lmer(resp.rt ~ s_age + s_size + s_word + (1+s_word|id), data = d)
comb2 = lmer(resp.rt ~ poly(s_age, 2, raw = TRUE) + s_size + s_word + (1+s_word|id), data = d)
comb3 = lmer(resp.rt ~ s_age + poly(s_size, 2, raw = TRUE) + s_word + (1+s_word|id), data = d)
comb4 = lmer(resp.rt ~ poly(s_age, 2, raw = TRUE) + poly(s_size, 2, raw = TRUE) + s_word + (1+s_word|id), data = d)
comb5 = lmer(resp.rt ~ poly(s_age, 3, raw = TRUE) + poly(s_size, 2, raw = TRUE) + s_word + (1+s_word|id), data = d)
comb6 = lmer(resp.rt ~ poly(s_age, 4, raw = TRUE) + poly(s_size, 2, raw = TRUE) + s_word + (1+s_word|id), data = d)
comb7 = lmer(resp.rt ~ poly(s_age, 4, raw = TRUE) + poly(s_size, 3, raw = TRUE) + s_word + (1+s_word|id), data = d)
comb8 = lmer(resp.rt ~ poly(s_age, 4, raw = TRUE) + poly(s_size, 4, raw = TRUE) + s_word + (1+s_word|id), data = d)

plot(compare_performance(comb1,comb2,comb3,comb4,comb5,comb6,comb7,comb8, metrics = 'common'))
anova(comb5,comb7)
anova(comb7,comb6)
anova(comb5,comb6) # comb5
anova(comb7,comb8)


plot_model(comb7, 'pred', terms = c('s_size [all]','s_age'))
