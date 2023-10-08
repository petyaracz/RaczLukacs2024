# models

setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(magrittr)
library(glue)
library(lme4)
library(broom.mixed)
library(sjPlot)
library(performance)

d = read_tsv('tidy/d.tsv') %>% 
  filter(!drop_participant,!drop_observation,!is.na(age),!nonce_word,correct)

load('analysis/models/fit11.Rda')
load('analysis/models/fit12.Rda')
load('analysis/models/fit15.Rda')

compareML(fit11,fit15) # no age: aic diff: 93, score diff: 122
compareML(fit12,fit15) # no vocab size: aic diff: 140, score diff: 123

# linear model #

hist(d$word_familiarity, breaks = 49)

d %<>% 
  mutate(
    participant_age_group = 
      case_when(
        participant_age <= 14 ~ '-14', 
        participant_age >= 65 ~ '65+',
        participant_age > 14 & participant_age < 65 ~ '15-64'
      ) %>% fct_relevel('15-64'),
    word_familiarity_level = ifelse(word_familiarity >= 25, 'low', 'high'),
    c_word_familiarity = word_familiarity - 25,
    c_participant_vocabulary_size = participant_vocabulary_size - 25,
    c_participant_age = participant_age - mean(participant_age)
  )

lmm1 = lmer(resp.rt ~ 1 + c_participant_vocabulary_size * participant_age_group * c_word_familiarity + (1|id) + (1|word), data = d, REML = F)

plot_model(lmm1, type = "pred", terms = c("c_word_familiarity","c_participant_vocabulary_size","participant_age_group"))

tidy(lmm1, conf.int = T) %>% 
  select(term,estimate,conf.low,conf.high)


# -- write -- #

save(lmm1, file = 'analysis/models/lmm1.Rda')

