# checks data and complains if things don't add up.
setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(magrittr)
library(glue)

# --- read-in --- #

col_spec = cols(
  id_spec = col_character(),
  n_mistakes_for_nonce_words = col_double(),
  percent_mistakes_for_nonce_words = col_double(),
  id = col_character(),
  data_type = col_character(),
  participant_cap_2 = col_double(),
  participant_cap_1 = col_double(),
  max_trial_number = col_double(),
  max_block = col_double(),
  n_mistakes_for_real_words_total = col_double(),
  block = col_double(),
  n_mistakes_for_real_words_per_bin = col_double(),
  sex = col_character(),
  yob = col_character(),
  edu = col_character(),
  start = col_character(),
  exp = col_character(),
  row_number = col_double(),
  block_trial_number = col_double(),
  trial_number = col_double(),
  word = col_character(),
  resp.keys = col_character(),
  resp.rt = col_double(),
  pos = col_character(),
  bin = col_double(),
  lfpm10r = col_double(),
  nonce_word = col_logical(),
  correct = col_logical(),
  link = col_character()
)

e1 = read_tsv('tidy/pilot1tidy.tsv', col_types = col_spec)
e2 = read_tsv('tidy/pilot2tidy.tsv', col_types = col_spec)
e3 = read_tsv('tidy/maintidy.tsv', col_types = col_spec)
sum = read_tsv('tidy/summary_tidy.tsv')

ee = bind_rows(e1,e2,e3)

# --- tests --- #

# do we have an outcome column?!

f0_a = any(
any(is.na(e1$correct)),
any(is.na(e2$correct)),
any(is.na(e3$correct))
)
# do we have a resp column?

f0_b = any(
any(is.na(e1$resp.rt)),
any(is.na(e2$resp.rt)),
any(is.na(e3$resp.rt))
)

# do we have our participant-level variables?

f0_c = any(
any(is.na(e1$participant_cap_1)),
any(is.na(e2$participant_cap_1)),
any(is.na(e3$participant_cap_1))
)

f0 = !all(f0_a,f0_b,f0_c)

# did the experiments stop where they should?

# e1
e1runs = e1 %>% 
  rowwise() %>% 
  filter(block %in% c(max_block,max_block - 1)) %>% 
  ungroup() %>% 
  group_by(id,start,data_type,block,max_block) %>% 
  count(correct) %>% 
  pivot_wider(names_from = correct, values_from = n, values_fill = 0) %>%
  mutate(enough_errors = `FALSE` == 3 | max_block == 50)

f1 = all(e1runs$enough_errors)

# for e2 this is trivially true if max_block = participant_cap which it is
e2runs = e2 %>% mutate(okay = participant_cap_1 == max_block)

f2 = all(e2runs$okay)

# for e3 this is trivially true if n trials = 250
e3runs = count(e3,id,data_type,start) %>% 
  mutate(okay = n == 250)

f3 = all(e3runs$okay)

# ref set

c1 = count(ee,max_trial_number,id,data_type,start,exp,max_block,participant_cap_1,n_mistakes_for_real_words_total, name = 'trial_count')

# n trials

f4 = all(c1$max_trial_number==c1$trial_count)
f5 = max(c1[c1$exp == 'exp1',]$max_trial_number) < 200
f6 = max(c1[c1$exp == 'exp2',]$max_trial_number) < 212 # one very unlucky id
f7 = all(c1[c1$exp == 'exp3',]$max_trial_number == 250)

# max block

f8 = all(c1$max_block < 51)

# participant cap

f9 = all(c1[c1$exp == 'exp1',]$max_block >= c1[c1$exp == 'exp1',]$participant_cap_1)
f10 = all(c1[c1$exp == 'exp2',]$max_block == c1[c1$exp == 'exp2',]$participant_cap_1)
f11 = all(c1[c1$exp == 'exp3',]$max_block >= c1[c1$exp == 'exp3',]$participant_cap_1)

# n mistakes

f12 = all(c1[c1$exp == 'exp1',]$n_mistakes_for_real_words_total <= c1[c1$exp == 'exp1',]$max_block * 3 | c1[c1$exp == 'exp1',]$trial_count < 10)
f13 = all(c1[c1$exp == 'exp2',]$n_mistakes_for_real_words_total <= c1[c1$exp == 'exp2',]$participant_cap_1 + 1)
f14 = all(c1[c1$exp == 'exp3',]$n_mistakes_for_real_words_total <= 200)

# all damis

ndami = sum %>% 
  filter(str_detect(id, 'DAMI')) %>% 
  nrow()

f15 = ndami == 17

# appropriate amount of nonce words

nonceWordCounter = function(dat){
  dat %>% 
    group_by(id) %>% 
    count(nonce_word) %>% 
    pivot_wider(names_from = nonce_word, values_from = n) %>% 
    mutate(
      van = ifelse(is.na(`TRUE`), 0, `TRUE`),
      nincs = ifelse(is.na(`FALSE`), 0, `FALSE`),
      nonce_word_ratio = van / (van + nincs),
      nincs_baj = nonce_word_ratio < .8
    ) %>% 
    pull(nincs_baj) %>% 
    all()
}

f16 = nonceWordCounter(e1)
f17 = nonceWordCounter(e2)
f18 = nonceWordCounter(e3)

f19 = e1 %>% 
  rowwise() %>% 
  mutate(okay = participant_cap_1 <= participant_cap_2) %>% 
  pull(okay) %>% 
  all()

f20 = e2 %>% 
  rowwise() %>% 
  mutate(okay = participant_cap_1 <= participant_cap_2) %>% 
  pull(okay) %>% 
  all()

f21 = e3 %>% 
  rowwise() %>% 
  mutate(okay = participant_cap_1 <= participant_cap_2) %>% 
  pull(okay) %>% 
  all()

# trials don't somehow restart

f22a = e1 %>% 
  count(word,id_spec) %>% 
  filter(n > 1) %>% 
  distinct(id_spec) %>% 
  nrow()

f22b = e2 %>% 
  count(word,id_spec) %>% 
  filter(n > 1) %>% 
  distinct(id_spec) %>% 
  nrow()

f22c = e3 %>% 
  count(id_spec) %>% 
  filter(n > 250) %>% 
  nrow()

f22 = all(f22a==0,f22b==0,f22c==0)

# --- running check --- #

big_flag = all(f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18,f19,f20,f21,f22)

ifelse(big_flag,
       glue('checks completed successfully.'),
       glue('check failed. look into _tests for deets.')
       )
