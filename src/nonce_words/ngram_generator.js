var makeGenerator = require('ngram-word-generator'),
//	bigramModel = require('./n2_min2_unique_exclor_model.json'),
	trigramModel = require('./n3_min4_unique_exclor_model.json'),
//    quatgramModel = require('./n4_min6_unique_exclor_model.json');

//var bigenerator = makeGenerator(bigramModel)
var trigenerator = makeGenerator(trigramModel)
//var quatgenerator = makeGenerator(quatgramModel)

for (let step = 0; step < 20000; step++) {
	const array2 = [3,4,5,6,7,8,9]
	array2.forEach(function (item) {
	  console.log(trigenerator(item));
	});
	//const array3 = [6,7,8,9]
	//array3.forEach(function (item) {
	//  console.log(trigenerator(item));
	//});
	//const array4 = [9,10,11,12]
	//array4.forEach(function (item) {
	//  console.log(bigenerator(item));
	//});
}
