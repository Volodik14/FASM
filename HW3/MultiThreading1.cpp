#include <condition_variable>
#include <iostream>
#include <random>
#include <thread>
#include <mutex>
#include <queue>
using namespace std;

mutex lockQueue;
condition_variable checkQueue;
queue<int> ids;
bool flagDone;
bool flagNotified;
int answers[10][10];
int studentsAnswers[10][10];

void studentFunc(int id, int* arr) {

	for (size_t i = 0; i < 10; i++) {
		arr[i] = rand() % 4 + 1;
	}
	// Adding id and notifying.
	{
		unique_lock<mutex> locker(lockQueue);
		ids.push(id);
		flagNotified = true;
		checkQueue.notify_one();
	}
}

void teacherFunc() {
	while (!flagDone)
	{
		unique_lock<mutex> locker(lockQueue);
		// Protection from wrong notifying.
		while (!flagNotified) 
			checkQueue.wait(locker);
		while (!ids.empty())
		{
			int res = 0;
			int id = ids.front();
			for (size_t i = 0; i < 10; i++)
			{
				if (answers[id][i] == studentsAnswers[id][i])
				{
					res++;
				}
			}
			std::cout << "Student #" << id << " got mark " << res << std::endl;
			ids.pop();
		}
		flagNotified = false;
	}
}

void fillArray() {
	for (size_t i = 0; i < 10; i++) {
		for (size_t j = 0; j < 10; j++) {
			answers[i][j] = rand() % 4 + 1;
		}
	}
}

int main() {
	srand(time(NULL));
	
	fillArray();
	
	thread teacherThread(teacherFunc);
	
	vector<thread> students;
	for (int i = 0; i < 10; i++)
		students.push_back(std::thread(studentFunc, i, ref(studentsAnswers[i])));
	for (auto& thread : students)
		thread.join();

	flagDone = true;

	teacherThread.join();
	return 0;
}