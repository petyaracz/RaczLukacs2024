# creates a curated word frequency list from our raw corpus data.
# the raw data are big.
# the frequency list is used in pilot1.

library(tidyverse)
setwd('~/Github/RaczLukacs2021/')
set.seed(1234)

first = function(){

hu = read_tsv('src/from_corpus/hu_list.txt')
freq = vroom::vroom('raczp_disamb_agg.tgz', col_names = F) # this is a word freq list from webcorpus 2, cite https://hlt.bme.hu/en/publ/nemeskey_2020
names(freq) = c('word', 'freq', 'tag', 'lemma')
freq2 = filter(freq, word %in% hu$word) 
write_tsv(freq2, 'src/from_corpusraczp_disamb_agg_hu_vroom.tsv')
freq2 = read_tsv('src/from_corpusraczp_disamb_agg_hu_vroom.tsv')
disp = vroom::vroom('src/dispersions_cutoff_2docs.tsv') # at least two docs per item, not in this repository
disp = select(disp, word, dispersion, doc_lengths, docs_count)
freq2 = left_join(freq2, disp)

return(freq2)
}

# freq2 = first()
freq2 = read_tsv('src/from_corpus/raczp_disamb_agg_hu_disp_vroom.tsv')

second = function(freq2){

corpus_magyar_total_size = 7417325169# this is the corpus with only magyar characters in it, but including hapaxes

words = freq2 %>%
  mutate(
    pos = case_when(
      tag == '[/N][Nom]' ~ 'noun',
      tag == '[/Adj][Nom]' ~ 'adjective',
      tag == '[/V][Prs.NDef.3Sg]' ~ 'verb',
      tag == '[/Adv]' ~ 'adverb'
    ),
    fpm = freq / corpus_magyar_total_size * 10^6,
    lfpm = log(fpm),
    lfpm10 = log10(fpm),
    ending = case_when(
      str_detect(word, 's[áé]g$') ~ '-sAg',
      str_detect(word, '[aeáéőóo]s$') ~ '-Os',
      str_detect(word, '[aeö]t$') ~ '-Ot',
      str_detect(word, 'l[ae]g$') ~ '-lAg',
      str_detect(word, '[ae]n$') ~ '-An',
      str_detect(word, '[óő]$') ~ '-O',
      str_detect(word, 'i$') ~ '-i',
      str_detect(word, '[ae]$') ~ '-A',
      str_detect(word, '[uü]l$') ~ '-Ul',
      str_detect(word, 'b[ae]n$') ~ '-bAn',
      str_detect(word, 'r[ae]$') ~ '-rA',
      str_detect(word, '[ae]l$') ~ '-Al',
      str_detect(word, 'ig$') ~ '-ig',
      str_detect(word, 'r[óő]l$') ~ '-rOl',
      str_detect(word, 'tt$') ~ '-tt',
      pos == 'adjective' & str_detect(word, 't$') ~ '-t'
    ),
    syllable_count = str_count(word, '[aáeéiíoóöőuúüű]'),
    proper_name = str_detect(word, '[AÁEÉIÍOÓÖŐUÚÜŰQWERTZUIOPASDFGHJKLYXCVBNM]'),
    stem = !is.na(pos) # these are mostly already stems
  )

return(words)
}

words = second(freq2)

third = function(words, n){

bins = tibble(
bin_min = seq(from = min(words$lfpm10), to = max(words$lfpm10), length.out = n + 1 )[1:n],
bin_max = seq(from = min(words$lfpm10), to = max(words$lfpm10), length.out = n + 1 )[2:(n + 1)],
bin3 = 1:n
)

wordsb = words %>% select(word, lfpm10)

words1 = crossing(words, bins) # warning, big df
words2 = filter(words1, lfpm10 >= bin_min)
words3 = filter(words2, lfpm10 <= bin_max)

words3 = arrange(words3, word, -lfpm10)

return(words3)
}

words3 = third(words, n = 75)

count(words3, bin3) %>% View

words3$bin = ifelse(words3$bin3 > 1, (words3$bin3 - 1), 1) # bin 2 missing
words3$bin = ifelse(words3$bin > 3, (words3$bin - 1), words3$bin) # bin 4 missing
words3$bin = ifelse(words3$bin > 50, 50, words3$bin) # cap it at bin 50
words3$bin3 = NULL
words3$lfpm = NULL

count(words3, bin) %>% View

fourth = function(words3){
  
  words4 = words3 %>% 
    filter(
      is.na(ending), 
      pos!='adverb', 
      !proper_name,
      syllable_count > 0,
      nchar(word) > 1
    ) %>% 
    arrange(word, pos, lfpm10, bin) %>% 
    filter(!duplicated(word))

return(words4)    
}

words4 = fourth(words3)

count(words4, bin) %>% View

words4 %>% 
  group_by(bin) %>% 
  sample_n(20) %>% 
  distinct(word, pos, lfpm10, bin) %>% 
  mutate(lfpm10r = round(lfpm10, 3)) %>% 
  select(-lfpm10) %>% 
  write_tsv('src/from_corpus/kezzel_szurni_uj.tsv')

# there was manual filtering involved here.
words5 = read_tsv('src/from_corpus/kezzel_szurve_uj.tsv')

missing = count(words5, bin) %>% filter(n != 20)
words4 %>%
  filter(
    !(word %in% words5$word),
    bin %in% missing$bin
    ) %>%
  distinct(word, pos, lfpm10, bin) %>%
  mutate(lfpm10r = round(lfpm10, 3)) %>% 
  select(-lfpm10) %>% 
  arrange(bin) %>%
  write_tsv('innen.tsv')

szavak = read_tsv('src/from_corpus/kezzel_szurve_uj.tsv')     
szavak = arrange(szavak, bin, lfpm10r, word, pos)
write_tsv(szavak, 'src/e1/szurt_szavak_log10_fix.tsv')

nonce = read_tsv('src/from_corpus/nonce_list.txt', col_names = F) %>% rename(target = X1)
hu = read_tsv('src/from_corpus/hu_list.txt')
hu2 = filter(hu, nchar(word) > 2)
nonce2 = sample_n(nonce, 1000)
write_tsv(nonce2, 'src/from_corpus/nonce_list_rand.txt')
