Supplementary Information: Older participants are slower in a visual
lexical decision task, but this is attenuated by a large vocabulary
================
Rácz, Péter
2 October, 2024

## Links

The code to run the experiments on Gitlab for pilot 1, pilot 2, and the
main experiment are
[**here**](https://gitlab.pavlovia.org/petyaraczbme/lex_span4),
[**here**](https://gitlab.pavlovia.org/petyaraczbme/lendulet_bme_szokiserlet_vegso),
and
[**here**](https://gitlab.pavlovia.org/petyaraczbme/lex-dec-task-random).

## File structure and workflow

We ran two pilot experiments and a main experiment. The stimulus list
for pilot 1 was based on a frequency list from [Hungarian Webcorpus
2](https://hlt.bme.hu/en/resources/webcorpus2). We host this list in
this repository. Cite us and the original if you want to use it.
Subsequent stimulus lists were based on results from pilot 1.

- src: corpus data in various processed forms
- raw: raw output of the Gitlab scripts running the experiments
- scripts: scripts to create the word lists, process the raw data,
  create the tidy data, and check on the processing
- tidy: tidy data for pilot 1, 2, and main
- analysis: scripts to analyse the tidy data from the main experiment

## Data dictionary for main data (tidy/d.tsv)

- id_spec: participant id with timestamp
- n_mistakes_for_nonce_words: n times participant said yes to non-word
- percent_mistakes_for_nonce_words: % participant said yes to non-word
- id: participant id
- data_type: did participant finish exp (they all did)
- participant_cap_2: counting participant vocab size v2
- participant_cap_1: counting participant vocab size v1
- max_trial_number: 250 for everyone
- max_block: 50 for everyone
- n_mistakes_for_real_words_total
- block
- n_mistakes_for_real_words_per_bin:n times part said no to real word
- yob: year of birth
- edu: years spent in education
- start: starting experiment
- exp: this is exp3
- row_number: row number in data
- block_trial_number: trial n 1-250 (only one block)
- trial_number: trial n 1-250
- word: target
- resp.keys: what key did part press
- resp.rt: part time \<- this is the outcome variable
- pos: target part of speech
- bin: target familiarity bin
- lfpm10r: log freq per 10 mil in Webcorpus 2, scaled
- nonce_word: this is a non-word
- correct: correct answer (y for word, n for non-word)
- link: link to exp
- missed_nonce_words: n non-words missed by part
- gender: part gender, self reported
- drop_participant: part meets exclusion criteria
- drop_observation: response meets exclusion criteria
- year_of_birth: year of birth tidy
- start_time: start time tidy
- start_year: start year
- age: year - yob
- answer: yes or no
- participant_age: age \<- predictor
- participant_vocabulary_size: vocab size \<- predictor
- word_familiarity: word familiarity bin \<- predictor

## Exclusion criteria

- drop_participant = missed_nonce_words \> 20
- drop_observation = resp.rt \> 4

``` r
# n obs
nrow(d)
```

    ## [1] 71608

``` r
# n part
length(unique(d$id_spec))
```

    ## [1] 467

``` r
# n filt obs
nrow(filt)
```

    ## [1] 113076

``` r
# n filt part
length(unique(filt$id_spec))
```

    ## [1] 472

``` r
# filt counts
filt |> 
  count(nonce_word,correct) |> 
  pivot_wider(names_from = nonce_word, values_from = n) |> 
  rename('non word' = `TRUE`, 'real word' = `FALSE`) |> 
  mutate(response = ifelse(correct, 'yes', 'no')) |> 
  select(response,`real word`,`non word`) |> 
  kable('simple')
```

| response | real word | non word |
|:---------|----------:|---------:|
| no       |     18016 |     1977 |
| yes      |     72365 |    20718 |

``` r
# young
nrow(idsy)
```

    ## [1] 80

``` r
# old
nrow(idso)
```

    ## [1] 387

## Model comparison

Three models fit on young and old data. lme4. ML. for main and resid
models, participant and word random intercept plus word familiarity
slope for participant. AIC, BIC, likelihood ratio test used for model
comparison. Models checked for collinearity using variance inflation
factor. (age and vocab size very collinear, so we decided not to test
interactions directly).

Young data: - Vocabulary: Is the vocabulary x age relationship linear or
polynomial? - Main: RT ~ part age, vocab size, word familiarity - Resid
Vocab/Age: RT ~ part age, variation in vocab size not explained by age
(residualised vocabulary size), word familiarity

``` r
# best models:

## -- young -- ##

## vocabulary
myv1 = lm(s_size ~ s_age, data = idsy)
## main
mys1 = lmer(resp.rt ~ 1 + s_age + s_word + s_size + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
## residualised
myr1 = lmer(resp.rt ~ 1 + s_age + res_size_age + s_word + (1+s_word|id) + (1|word), data = young, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
```

Young data: - Vocabulary: Is the vocabulary x age relationship linear or
polynomial? - Main: RT ~ part age, vocab size, education, word
familiarity - Resid Vocab/Age: RT ~ part edu, age, variation in vocab
size not explained by age (residualised vocabulary size), word
familiarity - Resid Vocab/Edu: RT ~ part age, edu, variation in vocab
size not explained by edu (residualised vocabulary size), word
familiarity

``` r
# best models ctd.:

## -- old -- ##

## vocabulary
mov1 = lm(s_size ~ 1 + s_edu + s_age, data = idso)
## main
mos1 = lmer(resp.rt ~ 1 + s_age + s_edu + s_word + s_size + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
## residualised
mor3 = lmer(resp.rt ~ 1 + s_edu + s_word + res_size_age * s_age + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
mor4 = lmer(resp.rt ~ 1 + s_age + s_word + res_size_edu * s_edu + (1+s_word|id) + (1|word), data = old, REML = F, control = lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=20000)))
```

## Plots in paper

![](figures/plot1-1.png)<!-- -->
