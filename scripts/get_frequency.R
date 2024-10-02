setwd('~/Github/RaczLukacs2024')

d = read_tsv('tidy/full_real_word_set.tsv')

c = read_tsv('~/Github/published/Racz2024/resource/webcorpus2freqlist/substantives_and_verbs_dict.gz')

c2 = c |> 
  filter(form %in% d$word)

d2 = c2 |> 
  rename(word = form) |> 
  arrange(-lemma_freq) |> 
  group_by(word) |> 
  slice(1) |> 
  mutate(
    fpm = freq / 8570, # per million
    lemma_fpm = lemma_freq / 8570,
    nchar = nchar(lemma)
  ) |> 
  select(word,fpm,lemma_fpm,nchar) |> 
  right_join(d)

write_tsv(d2, 'tidy/full_real_word_set_info.tsv')
