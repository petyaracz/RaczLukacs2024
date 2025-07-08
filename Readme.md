The effect of age, education, and vocabulary size on the speed of word
recognition across the lifespan
================
Rácz, Péter
8 July, 2025

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

## Stimulus info

| median_freq | mean_freq | median_lfreq | mean_lfreq | median_nchar | mean_nchar |
|------------:|----------:|-------------:|-----------:|-------------:|-----------:|
|        0.33 |     11.94 |         0.79 |      38.04 |            7 |       7.06 |

| pos       |   n |
|:----------|----:|
| adjective |  31 |
| noun      | 118 |
| verb      |  51 |

## Counts

| counts                       |      n |
|:-----------------------------|-------:|
| participants                 |    497 |
| observations                 | 124250 |
| participants, filtered       |    472 |
| observations, filtered       | 113076 |
| young participants, filtered |     80 |
| old participants, filtered   |    387 |

| response | real word | non word |
|:---------|----------:|---------:|
| no       |     18016 |     1977 |
| yes      |     72365 |    20718 |

    ## [1] "distribution of total response duration per participant:"

    ##       0%      25%      50%      75%     100% 
    ## 1.343503 2.352229 2.671501 3.074218 5.917920

## GAM and Factor analysis of age x vocabulary x education

    ## Factor Analysis using method =  minres
    ## Call: fa(r = vars, nfactors = 2, rotate = "varimax")
    ## Standardized loadings (pattern matrix) based upon correlation matrix
    ##         MR1  MR2   h2   u2 com
    ## s_age  0.10 0.38 0.15 0.85 1.2
    ## s_size 0.52 0.46 0.48 0.52 2.0
    ## s_edu  0.51 0.12 0.27 0.73 1.1
    ## 
    ##                        MR1  MR2
    ## SS loadings           0.54 0.37
    ## Proportion Var        0.18 0.12
    ## Cumulative Var        0.18 0.30
    ## Proportion Explained  0.59 0.41
    ## Cumulative Proportion 0.59 1.00
    ## 
    ## Mean item complexity =  1.4
    ## Test of the hypothesis that 2 factors are sufficient.
    ## 
    ## df null model =  3  with the objective function =  0.16 with Chi Square =  51.96
    ## df of  the model are -2  and the objective function was  0 
    ## 
    ## The root mean square of the residuals (RMSR) is  0 
    ## The df corrected root mean square of the residuals is  NA 
    ## 
    ## The harmonic n.obs is  326 with the empirical chi square  0  with prob <  NA 
    ## The total n.obs was  326  with Likelihood Chi Square =  0  with prob <  NA 
    ## 
    ## Tucker Lewis Index of factoring reliability =  1.062
    ## Fit based upon off diagonal values = 1
    ## Measures of factor score adequacy             
    ##                                                     MR1   MR2
    ## Correlation of (regression) scores with factors    0.63  0.54
    ## Multiple R square of scores with factors           0.40  0.29
    ## Minimum correlation of possible factor scores     -0.20 -0.42

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

Old data: - Vocabulary: Is the vocabulary x age relationship linear or
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

Combined data:

- Old and young data together
- We know that the age effect is non-linear. We try 2nd, 3rd, 4th order
  polynomials
- We also try these for vocabulary size. This is a lot of comparisons
  and we don’t take the results extremely very seriously.

``` r
comb5 = lmer(resp.rt ~ poly(s_age, 3, raw = TRUE) + poly(s_size, 2, raw = TRUE) + s_word + (1+s_word|id), data = d) # I choose you
```

## Tables in paper

| age_group |   n |
|:----------|----:|
| 9-14      |  47 |
| 14-19     |  47 |
| 19-20     |  47 |
| 20-21     |  47 |
| 21-23     |  47 |
| 23-26     |  47 |
| 26-35     |  47 |
| 35-47     |  46 |
| 47-61     |  46 |
| 61-90     |  46 |

| term        | estimate | std.error | statistic | conf.low | conf.high |
|:------------|---------:|----------:|----------:|---------:|----------:|
| (Intercept) |     2.58 |      0.10 |     25.42 |     2.38 |      2.78 |
| s_age       |    -1.02 |      0.16 |     -6.29 |    -1.34 |     -0.70 |
| s_word      |    -0.77 |      0.06 |    -12.94 |    -0.88 |     -0.65 |
| s_size      |    -0.37 |      0.19 |     -1.95 |    -0.75 |      0.00 |

| term        | estimate | std.error | statistic | conf.low | conf.high |
|:------------|---------:|----------:|----------:|---------:|----------:|
| (Intercept) |     2.08 |      0.06 |     32.50 |     1.96 |      2.21 |
| s_age       |     0.77 |      0.05 |     15.08 |     0.67 |      0.87 |
| s_edu       |    -0.58 |      0.09 |     -6.72 |    -0.75 |     -0.41 |
| s_word      |    -0.81 |      0.04 |    -20.23 |    -0.88 |     -0.73 |
| s_size      |    -0.66 |      0.09 |     -7.66 |    -0.83 |     -0.49 |

| term               | estimate | std.error | statistic | conf.low | conf.high |
|:-------------------|---------:|----------:|----------:|---------:|----------:|
| (Intercept)        |     1.64 |      0.04 |     36.85 |     1.55 |      1.73 |
| s_edu              |    -0.52 |      0.08 |     -6.50 |    -0.68 |     -0.37 |
| s_word             |    -0.81 |      0.04 |    -20.22 |    -0.88 |     -0.73 |
| res_size_age       |     0.02 |      0.12 |      0.14 |    -0.21 |      0.25 |
| s_age              |     0.62 |      0.05 |     13.19 |     0.53 |      0.71 |
| res_size_age:s_age |    -1.91 |      0.24 |     -7.93 |    -2.38 |     -1.44 |

| term               | estimate | std.error | statistic | conf.low | conf.high |
|:-------------------|---------:|----------:|----------:|---------:|----------:|
| (Intercept)        |     1.71 |      0.05 |     37.23 |     1.62 |      1.80 |
| s_age              |     0.76 |      0.05 |     14.94 |     0.66 |      0.86 |
| s_word             |    -0.81 |      0.04 |    -20.23 |    -0.88 |     -0.73 |
| res_size_edu       |    -1.20 |      0.21 |     -5.84 |    -1.61 |     -0.80 |
| s_edu              |    -0.75 |      0.08 |     -8.96 |    -0.91 |     -0.59 |
| res_size_edu:s_edu |     1.38 |      0.48 |      2.90 |     0.45 |      2.31 |

| term                         | estimate | std.error | statistic | conf.low | conf.high |
|:-----------------------------|---------:|----------:|----------:|---------:|----------:|
| (Intercept)                  |     2.53 |      0.08 |     30.74 |     2.37 |      2.69 |
| poly(s_age, 3, raw = TRUE)1  |    -3.45 |      0.51 |     -6.73 |    -4.45 |     -2.44 |
| poly(s_age, 3, raw = TRUE)2  |     7.62 |      1.29 |      5.90 |     5.09 |     10.15 |
| poly(s_age, 3, raw = TRUE)3  |    -3.74 |      0.93 |     -4.02 |    -5.57 |     -1.92 |
| poly(s_size, 2, raw = TRUE)1 |    -1.58 |      0.30 |     -5.32 |    -2.17 |     -1.00 |
| poly(s_size, 2, raw = TRUE)2 |     0.72 |      0.25 |      2.88 |     0.23 |      1.22 |
| s_word                       |    -0.74 |      0.01 |    -54.86 |    -0.76 |     -0.71 |

## Plots in paper

![](figures/plot1-1.png)<!-- -->![](figures/plot1-2.png)<!-- -->![](figures/plot1-3.png)<!-- -->![](figures/plot1-4.png)<!-- -->![](figures/plot1-5.png)<!-- -->![](figures/plot1-6.png)<!-- -->![](figures/plot1-7.png)<!-- -->![](figures/plot1-8.png)<!-- -->
