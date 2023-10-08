# parses pavlovia results files for pilot 1-2, main, processes data, writes out tidy tables to tidy/ also to google drive.
setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(magrittr)
library(glue)
library(googlesheets4)

gs4_auth(email = 'petermartonracz@gmail.com')

# --- functions --- #

# takes pavlovia output and word list, mops it up, returns tidy observation-level data
parseData = function(dat, wdat, exp_name){
  
  # suffering because of pavlovia
  if("within_block.thisN" %in% names(dat)){
    dat$withinBlock.thisN = dat$within_block.thisN 
  }
  
  # e3 doesn't have difficulty built in
  if(!"difficulty" %in% names(dat)){
    dat$difficulty = NA
  }
  
  dat %>% 
    mutate(
      exp = exp_name,
      row_number = row_number()
    ) %>% 
    filter(!Azonosító %in% drop) %>% # kick out stowaways
    filter(!is.na(resp.keys)) %>% # kick out krazy pavlovia id rows
    rename( # rename things
      'id' = Azonosító,
      'sex' = `Az Ön neme`,
      'yob' = `Születési éve`,
      'edu' = `Hány évet töltött az iskolapadban (egyetemet is beleértve)`,
      'start' = date,
      'block_trial' = withinBlock.thisN,
      'block' = difficulty
    ) %>% 
    mutate( # we're not doing python round here
      id = str_replace(id, '\t', ' '), # ezt nehezen hiszem el
      block_trial_number = as.double(block_trial) + 1,
      id_spec = glue('{id}: {start}')
    ) %>% 
    group_by(id_spec,data_type) %>% 
    mutate(trial_number = 1:n()) %>% 
    ungroup() %>% 
    select(
      id, id_spec, sex, yob, edu, start, data_type, exp,# participant-level
      row_number, block, block_trial_number, trial_number, # iterating
      word, resp.keys, resp.rt # data-level
    ) %>% 
    left_join(wdat, by = 'word') %>% # word data
    mutate(
      block = as.integer(block),
      nonce_word = is.na(pos),
      correct = case_when(
        !nonce_word & resp.keys == 'right' ~ T,
        nonce_word & resp.keys == 'right'~ F,
        nonce_word & resp.keys == 'left' ~ T,
        !nonce_word & resp.keys == 'left'~ F
      )
    )
  
}

# takes tidy observation-level data, returns o-l data w/ participant aggregates added
participantStopping = function(dat){
  
  dat %<>% 
    filter(!nonce_word,!correct) %>% 
    count(id,id_spec,data_type,block, name = 'n_mistakes_for_real_words_per_bin') %>% 
    right_join(dat, by = c("id", "id_spec", "data_type", "block")) %>% 
    mutate(n_mistakes_for_real_words_per_bin = ifelse(is.na(n_mistakes_for_real_words_per_bin), 0, n_mistakes_for_real_words_per_bin))
  
  dat %<>%
    distinct(id,id_spec,data_type,bin,n_mistakes_for_real_words_per_bin) %>% 
    group_by(id,id_spec,data_type) %>% 
    summarise(n_mistakes_for_real_words_total = sum(n_mistakes_for_real_words_per_bin, na.rm = T)) %>% 
    right_join(dat, by = c("id", "id_spec", "data_type"))
  
  dat %<>% 
    group_by(id,id_spec,data_type) %>% 
    summarise(max_block = max(block, na.rm = T)) %>% 
    right_join(dat, by = c("id", "id_spec", "data_type"))
  
  dat %<>% 
    group_by(id,id_spec,data_type) %>% 
    summarise(max_trial_number = max(trial_number)) %>% 
    right_join(dat, by = c("id", "id_spec", "data_type"))
  
  dat %<>% 
    distinct(id,id_spec,data_type,block,n_mistakes_for_real_words_per_bin) %>% 
    group_by(id,id_spec,data_type) %>% 
    filter(n_mistakes_for_real_words_per_bin > 1) %>%
    summarise(
      participant_cap_1 = min(block)
    ) %>% 
    right_join(dat, by = c("id", "id_spec", "data_type")) %>% 
    ungroup()
  
  dat %<>% 
    mutate(
      participant_cap_1 = ifelse(
        is.na(participant_cap_1) | participant_cap_1 < 1, max_block, participant_cap_1
      )
    )
  
  dat %<>% 
    distinct(id,id_spec,data_type,block,n_mistakes_for_real_words_per_bin) %>% 
    group_by(id,id_spec,data_type) %>% 
    filter(n_mistakes_for_real_words_per_bin > 2) %>%
    summarise(
      participant_cap_2 = min(block)
    ) %>% 
    right_join(dat, by = c("id", "id_spec", "data_type")) %>% 
    ungroup()
  
  dat %<>% 
    mutate(
      participant_cap_2 = ifelse(
        is.na(participant_cap_2) | participant_cap_2 < 0, max_block, participant_cap_2
      )
    )
}  

# takes tidy data, keeps first complete run per subject, unless no complete run, then first incomplete run.
keepFirst = function(dat){
  
  all_ids = distinct(dat,id)
  
  compl_ids = dat %>% 
    filter(data_type == 'complete data') %>% 
    distinct(id,start) %>% 
    arrange(id,start) %>% 
    group_by(id) %>% 
    mutate(n = 1:n()) %>% 
    filter(n == 1) %>% 
    select(id,start)
  
  if ( nrow(dat[dat$data_type == 'complete data',]) == nrow(dat) ){
    
    inner_join(dat,compl_ids, by = c("id", "start"))
    
  } else {
    
    incompl_ids = setdiff(all_ids$id,compl_ids$id)
    
    incompl_ids = dat %>% 
      filter(id %in% incompl_ids) %>% 
      distinct(id,start) %>%
      arrange(id,start) %>% 
      group_by(id) %>% 
      mutate(n = 1:n()) %>% 
      filter(n == 1) %>% 
      select(id,start)
    
    keep_ids = bind_rows(compl_ids,incompl_ids)
    inner_join(dat,keep_ids, by = c("id", "start"))
    
  }
  
}

# takes data, counts the number of mistakes for nonce words, also percent, joins back in data, returns data
countNonce = function(dat){
  dat %>% 
    filter(nonce_word) %>% 
    count(id_spec,resp.keys) %>% 
    pivot_wider(names_from = resp.keys, values_from = n, values_fill = 0) %>% 
    mutate(
      n_mistakes_for_nonce_words = right,
      percent_mistakes_for_nonce_words = ifelse((left + right) == 0, 0, right / (left + right) * 100) %>% round(0)
    ) %>% 
    select(id_spec,n_mistakes_for_nonce_words,percent_mistakes_for_nonce_words) %>% 
    left_join(dat, by = "id_spec")
}

# --- real word data --- #

w1 = read_tsv('src/word_lists/szurt_szavak_log10_fix.tsv')
w2 = read_tsv('src/word_lists/new_experiment_reference_list.tsv') %>% 
  select(word, pos, bin, lfpm10r)
w3 = read_tsv('src/word_lists/randreal.tsv') %>% 
  select(word, pos, bin, lfpm10r)

# --- raw datasets from pavlovia --- #

zipnames = list.files('raw')

f1 = zipnames[str_detect(zipnames, 'lex_span4')]
f2 = zipnames[str_detect(zipnames, 'bme_szokiserlet_vegso')]
f3 = zipnames[str_detect(zipnames, 'lex~dec~task~random')]

system(glue('unzip -o raw/{f1} -d raw/pilot1'))
system(glue('unzip -o raw/{f2} -d raw/pilot2'))
system(glue('unzip -o raw/{f3} -d raw/main'))

# watch out, this stacks if you don't get rid of old unzips
r1name = list.files('raw/pilot1/db/')
r2name = list.files('raw/pilot2/db/')
r3name = list.files('raw/main/db/')

if (!(length(r1name) == 1 & length(r2name) == 1 & length(r3name) == 1)){print('Balhé van.')}

r1 = read_csv(
  glue('raw/pilot1/db/{r1name}'),
  col_types = cols(.default = col_character())
)

r2 = read_csv(
  glue('raw/pilot2/db/{r2name}'),
  col_types = cols(.default = col_character())
)

r3 = read_csv(
  glue('raw/main/db/{r3name}'),
  col_types = cols(.default = col_character())
)

# --- incomplete data from pavlovia --- #

ri1name = list.files('raw/pilot1/data/')[str_detect(list.files('raw/ezx1/data/'),'PARTICIPANT.*csv')]
ri2name = list.files('raw/pilot2/data/')[str_detect(list.files('raw/pilot2/data/'),'PARTICIPANT.*csv')]
ri3name = list.files('raw/main/data/')[str_detect(list.files('raw/main/data/'),'PARTICIPANT.*csv')]

r1i = tibble(
    filename = glue('raw/pilot1/data/{ri1name}'),
  ) %>% 
  mutate(
    data = map(filename, ~ 
                 read_csv(
                   .,
                   col_types = cols(.default = col_character())
                 )
    )
  ) %>% 
  unnest(cols = c(data))

# no unfinished data for e2, probably destroyed in the famous data fire

r3i = tibble(
  filename = glue('raw/main/data/{ri3name}')
) %>% 
  mutate(
    data = map(filename, ~ 
                 read_csv(
                   .,
                   col_types = cols(.default = col_character())
                 )
    )
  ) %>% 
  unnest(cols = c(data))

# --- wrangling --- #

# labelling complete and incomplete files

r1$data_type = 'complete data'
r2$data_type = 'complete data'
r3$data_type = 'complete data'

r1i$data_type = 'incomplete data'
r3i$data_type = 'incomplete data'

# combining

r1b = bind_rows(r1,r1i)
r3b = bind_rows(r3,r3i)

# getting rid of FEFF

r1b$word = str_extract(r1b$word, '^.*$')
r2$word = str_extract(r2$word, '^.*$')
r3b$word = str_extract(r3b$word, '^.*$')

r1b$resp.keys = str_extract(r1b$resp.keys, '^.*$')
r2$resp.keys = str_extract(r2$resp.keys, '^.*$')
r3b$resp.keys = str_extract(r3b$resp.keys, '^.*$')

r1b$Azonosító = str_extract(r1b$Azonosító, '^.*$')
r2$Azonosító = str_extract(r2$Azonosító, '^.*$')
r3b$Azonosító = str_extract(r3b$Azonosító, '^.*$')

# dami id matching

r1b %<>% 
  mutate(
    Azonosító = 
      case_when(
        Azonosító == '1' ~ 'DAMI_1',
        Azonosító == 'DAMI2' ~ 'DAMI_2',
        Azonosító == '555_04' ~ 'DAMI_4',
        Azonosító == 'DAMI5' ~ 'DAMI_5',
        Azonosító == '6' ~ 'DAMI_6',
        Azonosító == '7' ~ 'DAMI_7',
        Azonosító == '5558' ~ 'DAMI_8',
        Azonosító == '55558' ~ 'DAMI_8',
        Azonosító == 'DAMI9' ~ 'DAMI_9',
        Azonosító == '555_10' ~ 'DAMI_10',
        Azonosító == '11' ~ 'DAMI_11',
        Azonosító == '555512' ~ 'DAMI_12',
        Azonosító == '555_13' ~ 'DAMI_13',
        Azonosító == '555_16' ~ 'DAMI_16',
        Azonosító == 'DAMI17' ~ 'DAMI_17',
        Azonosító == '18' ~ 'DAMI_18',
        Azonosító == '555518' ~ 'DAMI_18',
        Azonosító == 'DAMI19' ~ 'DAMI_19',
        Azonosító == '20' ~ 'DAMI_20',
        T ~ Azonosító
      )
  )

# col cleaning

drop = c("AKS7J4","Agi", "DORKAVAGYOK", "fruzsi", "fruzsiproba", "kresztanfolyam", "kriszti_proba", "nk", "petike", "Puskin2", "teszt", "NO_mask", "999", "99999", "999999", "9999", "0000", "ad", "iyoeex", "TunderIlona", "9999999", "eltorlek", "7318", "00000", "Ének", "Mamibega74", "t", "KT104", "KJ201", "KA104", "TESZT, BME, hallgató", "próba", "ezcsakegyteszt") # AKS7J4 somehow restarted in e2 and it's easier to drop them than to fix it.

# parsing

e1 = parseData(r1b, w1, 'exp1')
e2 = parseData(r2, w2, 'exp2')  
e3 = parseData(r3b, w3, 'exp3') %>% mutate(block = bin) # whatever

# re-takes #

drop = e3 %>% 
  count(id,id_spec) %>% 
  filter(n != 250) %>% 
  pull(id_spec)

e3 %<>% filter(!id_spec %in% drop)

# dunking empty id-s

e1 %<>% filter(!is.na(id)) # nc
e2 %<>% filter(!is.na(id)) # some decrease
e3 %<>% filter(!is.na(id)) # v little decrease

# participant stopping

e1 = participantStopping(e1)
e2 = participantStopping(e2)
e3 = participantStopping(e3) %>% mutate(max_block = 50)

# --- duplicates --- #

e1 = keepFirst(e1)
e2 = keepFirst(e2)
e3 = keepFirst(e3)

# --- n nonce wrong --- #

e1 = countNonce(e1)
e2 = countNonce(e2)
e3 = countNonce(e3)

# --- links --- #

e1$link = 'https://run.pavlovia.org/petyaraczbme/lex_span4/html/'
e2$link = 'https://pavlovia.org/run/petyaraczbme/lendulet_bme_szokiserlet_vegso/html/'
e3$link = 'https://run.pavlovia.org/petyaraczbme/lex-dec-task-random/html/'

# --- summary --- #

vocab_tests = bind_rows(e1,e2,e3) %>% 
  distinct(id,start,exp,link,participant_cap_1,participant_cap_2,max_block,max_trial_number,max_trial_number,n_mistakes_for_real_words_total,n_mistakes_for_nonce_words,percent_mistakes_for_nonce_words,data_type) %>% 
  select(id,start,exp,link,participant_cap_1,participant_cap_2,max_block,max_trial_number,max_trial_number,n_mistakes_for_real_words_total,n_mistakes_for_nonce_words,percent_mistakes_for_nonce_words,data_type) %>% 
  mutate_all(as.character) %>% 
  replace(is.na(.), '') %>% 
  mutate(start_time = lubridate::ymd_hms(start)) %>% 
  select(-start)

# --- write-out --- #

write_tsv(e1, 'tidy/pilot1tidy.tsv')
write_tsv(e2, 'tidy/pilot2tidy.tsv')
write_tsv(e3, 'tidy/maintidy.tsv')
write_tsv(vocab_tests, 'tidy/summary_tidy.tsv')

# -- gsheet -- #

vocab_tests %>%
  filter(exp == 'exp1') %>% 
  write_sheet(ss = 'https://docs.google.com/spreadsheets/d/1zaL4NMOvKOHbh1ma-WSYMJmljr2Wbbzvs8d1VtoxTcE/edit?usp=sharing', sheet = 'exp1')

vocab_tests %>% 
  filter(exp == 'exp2') %>% 
  write_sheet(ss = 'https://docs.google.com/spreadsheets/d/1zaL4NMOvKOHbh1ma-WSYMJmljr2Wbbzvs8d1VtoxTcE/edit?usp=sharing', sheet = 'exp2')

vocab_tests %>% 
  filter(exp == 'exp3') %>% 
  write_sheet(ss = 'https://docs.google.com/spreadsheets/d/1zaL4NMOvKOHbh1ma-WSYMJmljr2Wbbzvs8d1VtoxTcE/edit?usp=sharing', sheet = 'exp3')
