# -- head -- #

setwd('~/Github/RaczLukacs2024')

# -- fun -- #

residualise = function(dat){
  ids = dat |> 
    distinct(s_edu,s_size,s_age,id)
  
  res1 = lm(s_size ~ s_age, data = ids)
  res2 = lm(s_size ~ s_edu, data = ids)
  res3 = lm(s_edu ~ s_age, data = ids)
  res4 = lm(s_age ~ s_edu, data = ids)
  
  ids = ids |> 
    mutate(
      res_size_age = resid(res1),
      res_size_edu = resid(res2),
      res_edu_age = resid(res3),
      res_age_edu = resid(res4)
    )
  
  ids |> 
    right_join(dat)
}

tidi = function(model){
    model |> 
    tidy(conf.int = T) |> 
    filter(effect == 'fixed') |> 
    select(term,estimate,conf.low,conf.high)
  }

# -- wrangle -- #

# load all tidy, keep people w/ data
all = read_tsv('tidy/d.tsv') |> 
  filter(!is.na(age),!is.na(edu))

# drop bad observations and participants
filt = all |> 
  filter(!drop_participant,!drop_observation,!is.na(age))

# drop bad observations and participants, keep correct answers to real words, rescale
d = filt |> 
  filter(!nonce_word,correct) |> 
  mutate(
    participant_education = ifelse(as.double(edu) > 200, NA, as.double(edu)), # 200 is typo
    participant_education = ifelse(is.na(participant_education) & participant_age < 18, participant_age - 6, participant_education), # some na-s can be inferred. some not.
    s_age = scales::rescale(participant_age),
    s_edu = scales::rescale(participant_education),
    s_size = scales::rescale(participant_vocabulary_size),
    s_word = scales::rescale(word_familiarity)
  ) |> 
  filter(!is.na(participant_education)) # :(

# split
young = d |> 
  filter(participant_age < 18) |> 
  residualise()

old = d |> 
  filter(participant_age >= 18, !is.na(participant_education)) |> 
  residualise()

# summaries
idsy = young |> 
  distinct(id,participant_age,participant_vocabulary_size,s_age,s_size)

idso = old |> 
  distinct(id,participant_age,participant_vocabulary_size,participant_education,s_age,s_size,s_edu)

# -- cleanup -- #

rm(residualise) # don't need this no more
# rm(all)
# rm(d)
