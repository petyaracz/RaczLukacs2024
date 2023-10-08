# -- setup -- #

setwd('~/Github/RaczLukacs2024')

library(tidyverse)
library(magrittr)
library(glue)
library(knitr)
library(ggthemes)

library(mgcv)
library(itsadug)
library(broom)

library(patchwork)

# -- fun -- #

ML = function(model_object){
  sum_obj = summary(model_object)
  sum_obj$sp.criterion[[1]]
}

star = function(a,b){
  compo = compareML(a,b)
  compo$table$Sig.[[2]]
}

# -- load -- #

path =  glue('analysis/models/{list.files("analysis/models")}')
for (i in path){
  load(i)
}

# -- models -- #


## collinearity

c_fit07 = concurvity(fit07, full = F)

c_fit07$estimate # this doesn't look too bad: vocab size != age

## comparisons

# Do the individual effects do anything? lower AIC and lower REML score indicate better fit (for AIC, sort of)
compareML(fit01,fit02) # word
compareML(fit01,fit03) # vocabulary
compareML(fit01,fit04) # age
# The individual effects improve model fit.

# Do additions do anything? 5 word vocabulary 6 word age 7 word vocabulary age
compareML(fit02,fit05) # word: word x vocabulary
compareML(fit02,fit06) # word: word x age
compareML(fit02,fit07) # word: word x vocabulary x age

compareML(fit03,fit05) # vocabulary: word x vocabulary
compareML(fit03,fit07) # vocabulary: word x vocabulary x age

compareML(fit04,fit06) # age: word x age
compareML(fit04,fit07) # age: word x vocabulary x age

# The model with all three predictors is better. This is a rundown of How Additive Models Work for word- and participant-level predictors. 
# Now we can ask about interactions.

# 12 word and age int 13 vocab and age int 14 word and vocab int and age and vocab int 15 all
compareML(fit07,fit11) # word-vocab
compareML(fit07,fit12) # word-age
compareML(fit07,fit13) # NOPE vocab-age

compareML(fit12,fit14) # yes vocab-age
compareML(fit13,fit14) # yes word-age

compareML(fit12,fit13) # word-age > vocab-age.
compareML(fit11,fit15)
compareML(fit12,fit15)
compareML(fit13,fit15) # best fit seems to be unequivocally for three-way.
compareML(fit07,fit15)

# -- pred -- #

# vis.gam(fit15, view=c("participant_vocabulary_size", "word_familiarity"), plot.type="contour",color="terrain")
# vis.gam(fit15, view=c("participant_vocabulary_size", "participant_age"), plot.type="contour",color="terrain")
# vis.gam(fit15, view=c("participant_age", "word_familiarity"), plot.type="contour",color="terrain")
# vis.gam(fit15, view=c("participant_vocabulary_size", "word_familiarity"), plot.type="contour",color="terrain")
# 
plot(fit15, select = 1, rug = T, scheme = 1)
fvisgam(fit15, view = c("participant_vocabulary_size", "word_familiarity"))
fvisgam(fit15, view = c("participant_age", "word_familiarity"))
fvisgam(fit15, view = c("participant_age", "participant_vocabulary_size"))

sumfit15 = tidy(fit15)
sumfit15
knitr::kable(sumfit15, digits = 3, format = 'simple')

# -- put all this in a table -- #

# get AIC, score. compare everything to fit15.
# it's physically impossible to loop through gam model objects.
# *bob belcher saying "unbelievable"*

star(fit15,fit14);star(fit15,fit13);star(fit15,fit12);star(fit15,fit11);star(fit15,fit07);star(fit15,fit06);star(fit15,fit05);star(fit15,fit04);star(fit15,fit03);star(fit15,fit02);star(fit15,fit01)
# all of them are *** as I checked with my googly eyes
AIC(fit14);AIC(fit13);AIC(fit12);AIC(fit11);AIC(fit07);AIC(fit06);AIC(fit05);AIC(fit04);AIC(fit03);AIC(fit02);AIC(fit01)
# formulae
formula(fit15);formula(fit14);formula(fit13);formula(fit12);formula(fit11);formula(fit07);formula(fit06);formula(fit05);formula(fit04);formula(fit03);formula(fit02);formula(fit01)
# aic
model_formulae_15_01 = c("resp.rt ~ 1 + te(word_familiarity, participant_vocabulary_size, participant_age) + (1|participant) + (1|word)", "resp.rt ~ 1 + te(participant_age, word_familiarity) + te(participant_vocabulary_size, participant_age) + (1|participant) + (1|word)", "resp.rt ~ 1 + s(word_familiarity) + te(participant_vocabulary_size, participant_age) + (1|participant) + (1|word)", "resp.rt ~ 1 + te(word_familiarity, participant_age) + (1|participant) + (1|word)", "resp.rt ~ 1 + te(word_familiarity, participant_vocabulary_size) + (1|participant) + (1|word)", "resp.rt ~ 1 + s(word_familiarity) + s(participant_vocabulary_size) + s(participant_age) + (1|participant) + (1|word)", "resp.rt ~ 1 + s(word_familiarity) + s(participant_age) + (1|participant) + (1|word)", "resp.rt ~ 1 + s(word_familiarity) + s(participant_vocabulary_size) + (1|participant) + (1|word)", "resp.rt ~ 1 + s(participant_age) + (1|participant) + (1|word)", "resp.rt ~ 1 + s(participant_vocabulary_size) + (1|participant) + (1|word)", "resp.rt ~ 1 + s(word_familiarity) + (1|participant) + (1|word)", "resp.rt ~ 1 + (1|participant) + (1|word)")
model_aics_15_to_01 = c(97320.44, 97458.09, 97529.61, 97460.75, 97413.46, 97529.82, 97531.59, 97531.55, 97536.06, 97535.68, 97533.71, 97538.01)
model_mls_15_to_01 = c(49648.25, 49702.67, 49720.14, 49771.24, 49770.23, 49755.98, 49797.13, 49824.05, 49916.81, 49943.89, 49887.23, 50006.94)
formula(fit01)

gamms = tibble(
  formula = model_formulae_15_01,
  aic = model_aics_15_to_01,
  ml = model_mls_15_to_01
)

write_tsv(gamms, 'analysis/model_table.tsv')
