# do some final wrangling on the main tidy data before we analyse it

# --- header --- #

setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(magrittr)
library(glue)

# --- read-in --- #

col_spec = cols(
  .default = col_double(),
  id = col_character(),
  id_spec = col_character(),
  sex = col_character(),
  yob = col_character(),
  edu = col_character(),
  exp = col_character(),
  start = col_character(),
  word = col_character(),
  resp.keys = col_character(),
  pos = col_character(),
  nonce_word = col_logical(),
  correct = col_logical(),
  data_type = col_character(),
  link = col_character()
)

# --- read-in --- #

# e1 =  read_tsv('tidy/pilot1tidy.tsv', col_types = col_spec)
# e2 =  read_tsv('tidy/pilot2tidy.tsv', col_types = col_spec)
e3 =  read_tsv('tidy/maintidy.tsv', col_types = col_spec)

# --- wrangling --- #

d = e3 %>%
  filter(data_type == 'complete data') %>% 
  arrange(row_number) %>% 
  group_by(id) %>% 
  slice(1:250) %>% 
  ungroup()

# count(d,id) %>% View # 326

# fix age
d %<>% 
  mutate(
    yob = case_when(
      yob == '1880' ~ '1980',
      yob == '2o12' ~ '2012',
      T ~ yob
    )
  )

missed_words = d %>% 
  filter(nonce_word,!correct) %>% 
  count(id, name = 'missed_nonce_words')

d = full_join(d,missed_words, by = 'id') %>% 
  mutate(
    gender = ifelse(
      str_detect(sex, '^[NnGPMLJl]'), 'f', 'm'
    ),
    id = as.factor(id),
    word = as.factor(word),
    # drop_participant = missed_nonce_words > 10 | participant_cap_1 < 10, # old criteria
    drop_participant = missed_nonce_words > 20, # new, easier criteria
    drop_observation = resp.rt > 4,
    bin = 51 - bin,
    year_of_birth = str_extract(yob, '^[0-9]{4}') %>% 
      as.double(),
    start_time = lubridate::ymd_hms(start),
    start_year = str_extract(start_time, '^[0-9]{4}') %>% 
      as.double(),
    age = start_year - year_of_birth,
    answer = case_when(
      correct ~ 'yes',
      !correct ~ 'no'
    ),
    participant_age = age,
    participant_vocabulary_size = participant_cap_1,
    word_familiarity = bin
  ) %>% 
  sample_n(n()) %>% 
  select(-sex)

d2 = d %>% 
  filter(!drop_participant,!drop_observation,!is.na(age),!nonce_word,correct)

# -- write -- #

write_tsv(d, 'tidy/d.tsv')
write_tsv(d, 'tidy/d_filt.tsv')
