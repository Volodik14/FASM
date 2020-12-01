#include <iostream>
#include <thread>
#include <queue>
#include <string>
#include <omp.h>

using namespace std;

queue<int> works;
vector<int> results;
class Student
{
    bool hasScore;
    int score;
    int number;
    void printMessage(string message)
    {
#pragma omp critical(print)
        {
            cout << "Student #" << number << ": " << message << endl;
        }
    }

public:
    Student(int n)
    {
        number = n;
        hasScore = false;
        // Условие для генерации псевдослучайных чисел.
        srand(static_cast<unsigned>(n * n + static_cast<unsigned>(time(0))));
    }
    void startExam()
    {
        printMessage("I am starting an exam!");
        int time = rand() % 11 + 5;
        this_thread::sleep_for(chrono::seconds(time));
        {
#pragma omp critical(queue)
            {
                printMessage("I have finished!");
                works.push(number);
            }
        }
        while (!hasScore)
        {
            int a;
#pragma omp critical(scores)
            {
                a = results[number - 1];
            }
            if (a != 0)
            {
#pragma omp critical(scores)
                {
                    score = results[number - 1];
                }
                printMessage("My score is " + to_string(score) + ".");
                hasScore = true;
            }
        }
    }
};

class Teacher
{
public:
    static void checkWork(int n)
    {
#pragma omp critical(print)
        {
            cout << "Teacher: I'm checking work of student #" << n << "!" << endl;
        }
        int time = rand() % 3 + 1;
        this_thread::sleep_for(chrono::seconds(time));
        int score = rand() % 10 + 1;

#pragma omp critical(print)
        {
            cout << "Teacher: I have checked work of student #" << n << "! Score is " << score << endl;
        }
#pragma omp critical(scores)
        {
            results[n - 1] = score;
        }
    }
    static void startExam(int numberOfStudents)
    {
        int numberOfCheckedWorks = 0;
        while (numberOfCheckedWorks != numberOfStudents)
        {
            while (!works.empty())
            {
                int work;
#pragma omp critical(queue)
                {
                    work = works.front();
                    works.pop();
                }
                checkWork(work);
                numberOfCheckedWorks++;
            }
        }
    }
};

void fillArray(int n)
{
    for (int i = 0; i < n; i++)
    {
        results.push_back(0);
    }
}

void threadStudentFunction(int a)
{
    Student stud = Student(a);
    stud.startExam();
}

int main() {
    int numberOfStudents;
    cout << "Number of students:";
    cin >> numberOfStudents;
    if (numberOfStudents <= 0) {
        cout << "Input data must be positive number > 0!" << endl;
        system ("pause");
        return 0;
    }
    results = vector<int>(numberOfStudents);
    fillArray(numberOfStudents);

#pragma omp parallel num_threads(numberOfStudents + 1)
    {
        auto numberOfThreads = omp_get_thread_num();
        if (numberOfThreads == 0)
        {
            Teacher::startExam(numberOfStudents);
        }
        else
        {
            threadStudentFunction(omp_get_thread_num());
        }
    }
    //Чтобы сразу не пропадало окно.
    system ("pause");
    return 0;
}