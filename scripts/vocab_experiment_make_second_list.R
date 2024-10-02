# makes revamped word list based on results of pilot 1, to be used in pilot 2 and main.
# note:
# so we had a cutoff date and then created the word list. but then we kept running people for pilot 1 so the current pilot1tidy.tsv has more observations than what we originally worked with. I introduced a cut-off date to capture the data we used originally but I did this after the fact so it might be slightly off. anyway the logic is the same.
setwd('~/Github/RaczLukacs2022')

library(tidyverse)
library(magrittr)

e1 = read_tsv('tidy/pilot1tidy.tsv', 
              col_types = cols(
                .default = col_double(),
                id = col_character(),
                id_spec = col_character(),
                data_type = col_character(),
                exp = col_character(),
                link = col_character(),
                sex = col_character(),
                yob = col_character(),
                edu = col_character(),
                start = col_character(),
                word = col_character(),
                resp.keys = col_character(),
                pos = col_character(),
                nonce_word = col_logical(),
                correct = col_logical()
              )
            )

#####################
# filter roughly for cutoff for word list
#####################

e1 %<>% 
  mutate(startdate = lubridate::ymd_hms(start)) %>% 
  filter(
    data_type == 'complete data',
    startdate < lubridate::as_date('2020-10-30')
  ) 

word_data = e1 %>%
  ungroup() %>% 
  count(word, pos, bin, lfpm10r, correct, nonce_word) %>% 
  pivot_wider(names_from = correct, values_from = n, values_fill = list(n = 0)) %>% 
  rename(correct_answers = `TRUE`, incorrect_answers = `FALSE`) %>% 
  mutate(
    correct_odds = (correct_answers+1) / (incorrect_answers+1),
    correct_log_odds = log(correct_odds)
  )

#####################
# summary stats
#####################

e1sum = e1 %>% 
  mutate(
    sex_female = str_detect(sex, '^[nN]'),
    age = str_extract(yob, '^[0-9]{4}') %>% 
      as.double(),
    age = 2020-age
  ) %>% 
  distinct(id,sex_female,age)

nrow(e1sum)
e1sum %>% count(sex_female)
e1sum %>% summarise(median_age = median(age, na.rm = T))

e1 %>% count(word,nonce_word) %>% 
  summarise(
    max_n = max(n),
    median_n = median(n),
    min_n = min(n)
    )
  
#####################
# tidy code to make new list
#####################

# real and nonce words

real_words = filter(word_data, !nonce_word)
nonce_words = filter(word_data, nonce_word) %>% 
  arrange(-correct_log_odds)

write_tsv(real_words, 'tidy/full_real_word_set.tsv')

# residuals

fit1 = lm(correct_log_odds ~ bin, data = real_words)
with(real_words, cor.test(correct_log_odds,lfpm10r)) # .56
real_words$residual = fit1$residuals
real_words$pred = predict(fit1)

new_list = real_words %>% 
  arrange(residual) %>% 
  mutate(
    rank_total = 1:900,
    upper_band_total = rank_total >= 701
  ) %>% 
  group_by(bin) %>% 
  arrange(residual) %>% 
  mutate(
    rank_block = 1:n(),
    upper_band_block = rank_block >= 15
  ) %>% 
  ungroup()

# filter and order

new_list %<>%
  filter(
    !(word %in% c('indulatú', 'oikosz', 'bouillon', 'nyüvök', 'nek'))
  ) %>% 
  filter(!upper_band_total, !upper_band_block) %>% 
  select(-upper_band_total,-upper_band_block,-rank_total,-rank_block,-pred,-residual) %>%
  arrange(-correct_log_odds) %>% 
  mutate(
    rank = 1:n(),
    bin = ntile(rank, 50)
  ) %>% 
  group_by(bin) %>% 
  sample_n(12) %>% 
  ungroup() %>% 
  arrange(bin,-correct_log_odds)

new_nonce = nonce_words %>% 
  arrange(-correct_log_odds) %>% 
  top_n(200) %>% 
  sample_n(n()) %>% 
  mutate(
    bin = rep(1:50, 4)
  )

new_list %<>%
  bind_rows(new_nonce) %>% 
  arrange(bin)

# write_tsv(new_list, 'the file name is src/word_lists/new_experiment_reference_list.tsv') # this path is wrong on purpose

# passing on to pavlovia

# to_new = new_list %>% 
#   mutate(
#     difficulty = bin,
#     word_type = case_when(
#       nonce ~ 'nonce',
#       !nonce ~ 'real'
#     ),
#     correct_answer = case_when(
#       nonce ~ 'left',
#       !nonce ~ 'right'
#     )
#   )%>% 
#   select(
#     word,correct_answer,word_type,difficulty,bin
#   ) %>% 
#   ungroup()

# to_new %>%
#   group_by(bin) %>%
#   nest() %>% 
#   pwalk(~write_csv(x = .y, file = glue('~/Github/Pavlovia/uj_szokiserlet/blocks/block{.x}.csv') ) )

# tibble(
#   block_name = glue('blocks/block{1:50}.csv')
# ) %>% 
#   write_csv(glue('~/Github/Pavlovia/uj_szokiserlet/master.csv'))
