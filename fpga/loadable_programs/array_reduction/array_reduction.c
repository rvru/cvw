
#define LENGTH 10

int main(){

	int volatile result = 0;
	int values[LENGTH];

	for(int i = 0; i < LENGTH; i++){

		values[i] = i*5;

	}

	for(int j = 0; j < LENGTH; j++){

		result += values[j];

	}

	return 0;

}
