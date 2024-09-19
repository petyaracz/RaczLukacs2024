# -- head -- #

setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(glue)
library(lme4)
library(knitr)
library(broom.mixed)
library(performance)
library(sjPlot)
library(patchwork)

all = read_tsv('tidy/d.tsv')

d = all |> 
  filter(!drop_participant,!drop_observation,!is.na(age)) |> 
  filter(!nonce_word,correct) |> 
  mutate(
    participant_education = ifelse(as.double(edu) > 200, NA, as.double(edu)),
    s_age = scales::rescale(participant_age),
    s_edu = scales::rescale(participant_education),
    s_size = scales::rescale(participant_vocabulary_size),
    s_word = scales::rescale(word_familiarity)
  )

# split
young = d |> 
  filter(participant_age < 18)
old = d |> 
  filter(participant_age >= 18, !is.na(participant_education))

# residualisation
ids = old |> 
  distinct(s_edu,s_size,s_age,id)

res1 = lm(s_size ~ s_age, data = ids)
res2 = lm(s_size ~ s_edu, data = ids)
res3 = lm(s_edu ~ s_age, data = ids)

old = ids |> 
  mutate(
    res_size_age = resid(res1),
    res_size_edu = resid(res2),
    res_edu_age = resid(res3)
  ) |> 
  right_join(old)

# tidi fun
tidi = partial(tidy, conf.int = T)

# -- viz -- #

ids |> 
  ggplot(aes(s_edu,s_size)) +
  geom_point() +
  geom_smooth(method = 'lm') +
  theme_bw()

d |> 
  summarise(mean = mean(resp.rt), .by = c(participant_age,id)) |> 
  ggplot(aes(participant_age,mean)) +
  geom_point() +
  geom_smooth() +
  theme_bw() +
  xlab('participant age') +
  scale_x_continuous(breaks = seq(0,90,3)) +
  ylab('mean participant response time') +
  ggtitle('all participants')

d |> 
  distinct(participant_age,participant_vocabulary_size,id) |> 
  ggplot(aes(participant_age,participant_vocabulary_size)) +
  geom_point() +
  geom_smooth() +
  theme_bw() +
  scale_x_continuous(breaks = seq(0,90,3)) +
  xlab('participant age') +
  ylab('participant vocabulary size')

# -- models: young -- #

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
fit21 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

# 2-way interactions
fit22 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit23 = lmer(resp.rt ~ 1 + s_age + s_edu * s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit24 = lmer(resp.rt ~ 1 + s_age + s_edu + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

# bad 2-way interactions
fit21b = lmer(resp.rt ~ 1 + s_age * s_edu + s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit21c = lmer(resp.rt ~ 1 + s_age * s_size + s_edu + s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit21d = lmer(resp.rt ~ 1 + s_age + s_size * s_edu + s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

check_collinearity(fit21b)
check_collinearity(fit21c)
check_collinearity(fit21d)

# 3-way interactions
fit25 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu * s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit26 = lmer(resp.rt ~ 1 + s_age + s_edu * s_word + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit27 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit28 = lmer(resp.rt ~ 1 + s_age * s_word + s_edu * s_word + s_size * s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

perf_table_old = compare_performance(fit21,fit22,fit23,fit24,fit25,fit26,fit27,fit28, metrics = 'common')
arrange(perf_table_old,-AIC) 
arrange(perf_table_old,-BIC) 

anova(fit23,fit21)

plot_model(fit23, 'est') +
  theme_bw() +
  geom_hline(yintercept = 0, lty = 2)
tidi(fit23)
plot_model(fit23, 'pred', terms = c('s_word','s_edu')) +
  theme_bw() +
  scale_colour_viridis_d() +
  scale_fill_viridis_d()

# -- resid models -- #

fit31 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + res_size_age + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit32 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + res_size_edu + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit33 = lmer(resp.rt ~ 1 + s_edu + s_word + res_size_age * s_age + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit34 = lmer(resp.rt ~ 1 + s_age + s_word + res_size_edu * s_edu + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

tidi(fit31)
tidi(fit32)
tidi(fit33)
tidi(fit34)
plot_model(fit33, 'pred', terms = c('s_age','res_size_age')) +
  theme_bw() +
  scale_colour_viridis_d(option = "C") +
  scale_fill_viridis_d(option = "C")
plot_model(fit34, 'pred', terms = c('s_edu','res_size_edu')) +
  theme_bw() +
  scale_colour_viridis_d(option = "E") +
  scale_fill_viridis_d(option = "E")

# -- old: age and education -- #

fit41 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit42 = lmer(resp.rt ~ 1 + s_age + s_edu + res_size_age + s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit43 = lmer(resp.rt ~ 1 + s_age + s_edu + res_size_edu + s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit44 = lmer(resp.rt ~ 1 + s_age * res_size_age + s_edu +  s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
fit45 = lmer(resp.rt ~ 1 + s_edu * res_size_edu + s_age +  s_word + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))

compare_performance(fit41,fit42,fit44, metrics = 'common')
compare_performance(fit41,fit43,fit45, metrics = 'common')
test_likelihoodratio(fit42,fit44)
test_likelihoodratio(fit43,fit45)

plot_model(fit44)
plot_model(fit44, 'pred', terms = c('s_age','res_size_age')) +
  theme_bw() +
  scale_colour_viridis_d() +
  scale_fill_viridis_d()

plot_model(fit45)
plot_model(fit45, 'pred', terms = c('s_edu','res_size_edu')) +
  theme_bw() +
  scale_colour_viridis_d() +
  scale_fill_viridis_d()

# nice.