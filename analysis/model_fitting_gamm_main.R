# models

setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(magrittr)
library(glue)
library(mgcv)
library(itsadug)

d = read_tsv('tidy/d.tsv') %>% 
  filter(!drop_participant,!drop_observation,!is.na(age),!nonce_word,correct)

## series 00

# 01 intercept-only model
fit01 = bam(resp.rt ~ 1 + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit01, file = 'analysis/models/fit01.Rda')
print('done 01')

# 02 only word effect
fit02 = bam(resp.rt ~ 1 + s(word_familiarity, k = 5, bs = 'tp') + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit02, file = 'analysis/models/fit02.Rda')
print('done 02')

# 03 only vocabulary effect
fit03 = bam(resp.rt ~ 1 + s(participant_vocabulary_size, k = 5, bs = 'tp') + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit03, file = 'analysis/models/fit03.Rda')
print('done 03')

# 04 only age effect
fit04 = bam(resp.rt ~ 1 + s(participant_age, k = 5, bs = 'tp') + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit04, file = 'analysis/models/fit04.Rda')
print('done 04')

# 05 word and vocabulary effects
fit05 = bam(resp.rt ~ 1 + s(word_familiarity, k = 5, bs = 'tp') + s(participant_vocabulary_size, k = 5, bs = 'tp') + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit05, file = 'analysis/models/fit05.Rda')
print('done 05')

# 06 word and age effects
fit06 = bam(resp.rt ~ 1 + s(word_familiarity, k = 5, bs = 'tp') + s(participant_age, k = 5, bs = 'tp') + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit06, file = 'analysis/models/fit06.Rda')
print('done 06')

# 07 all three
fit07 = bam(resp.rt ~ 1 + s(word_familiarity, k = 5, bs = 'tp') + s(participant_vocabulary_size, k = 5, bs = 'tp') + s(participant_age, k = 5, bs = 'tp') + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit07, file = 'analysis/models/fit07.Rda')
print('done 07')

## series 10

# 11 word and vocabulary int
fit11 = bam(resp.rt ~ 1 + te(word_familiarity, participant_vocabulary_size, k = c(5,5), bs = c('tp','tp')) + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit11, file = 'analysis/models/fit11.Rda')
print('done 11')

# 12 word and age int
fit12 = bam(resp.rt ~ 1 + te(word_familiarity, participant_age, k = c(5,5), bs = c('tp','tp')) + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit12, file = 'analysis/models/fit12.Rda')
print('done 12')

# 13 vocab and age int
fit13 = bam(resp.rt ~ 1 + s(word_familiarity, k = 5, bs = 'tp') + te(participant_vocabulary_size, participant_age, k = c(5,5), bs = c('tp','tp')) + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit13, file = 'analysis/models/fit13.Rda')
print('done 13')

# 14 word and age int and age and vocab int
fit14 = bam(resp.rt ~ 1 + te(participant_age, word_familiarity, k = c(5,5), bs = c('tp','tp')) + te(participant_vocabulary_size, participant_age, k = c(5,5), bs = c('tp','tp')) + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit14, file = 'analysis/models/fit14.Rda')
print('done 14')

# 15 everything
fit15 = bam(resp.rt ~ 1 + te(participant_vocabulary_size, participant_age, word_familiarity, k = c(5,5,5), bs = c('tp','tp','tp')) + s(id, bs = 're') + s(word, bs = 're'), data = d, method = 'ML')
save(fit15, file = 'analysis/models/fit15.Rda')
print('done 15')