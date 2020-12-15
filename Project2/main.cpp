#include <iostream>
#include <vector>
#include <queue>
#include <mutex>
#include <semaphore.h>
#include <thread>

using namespace std;

struct Product{
    int id;
    int shop;
};

vector<queue<int>> queues(2);
vector<Product> allProducts;

int servedCustomers = 0;
int globalId = 0;
int globalIdShop = 0;

// Generating products with different id.
void generateProducts(int countOfCustomers, int maxCountOfProducts){
    int id;
    for (int i = 0; i < countOfCustomers / 2; ++i) {
        for (int j = 0; j < maxCountOfProducts; ++j) {
            Product product;
            product.id = id;
            product.shop = 0;
            allProducts.push_back(product);
            id++;
        }
    }
    for (int i = countOfCustomers / 2; i < countOfCustomers; ++i) {
        for (int j = 0; j < maxCountOfProducts; ++j) {
            Product product;
            product.id = id;
            product.shop = 1;
            allProducts.push_back(product);
            id++;
        }
    }
    cout << "list of products:" << endl;
    for (auto& product : allProducts)
        cout << "\tproduct #" << product.id << " shop #" << product.shop << endl;
    cout << endl;
}


void customerFunction(vector<sem_t> *shop_sems, int maxCountOfProducts, sem_t *customer_semaphore,
                      mutex *generation_mutex, mutex *queue_mutex, mutex *console_mutex, mutex *served_mutex){
    vector<Product> shoppingList;
    generation_mutex->lock();
    int myId = globalId++;
    srand(static_cast<unsigned>(myId * myId + static_cast<unsigned>(time(nullptr))));
    int countOfProducts = rand() % maxCountOfProducts + 1;
    shoppingList.reserve(countOfProducts);
    for (int i = 0; i < countOfProducts; ++i) {
        shoppingList.push_back(allProducts.at(rand() % allProducts.size()));
    }
    generation_mutex->unlock();
    console_mutex->lock();
    cout << "Customer #" << myId << ": my shopping list is ";
    for (int i = 0; i < countOfProducts; ++i) {
        cout << shoppingList[i].id << " ";
    }
    cout << endl;
    console_mutex->unlock();

    while (!shoppingList.empty()){
        queue_mutex->lock();
        queues[shoppingList.back().shop].push(myId);

        console_mutex->lock();
        cout << "Customer #" << myId << ": I have enqueued into the shop #" << shoppingList.back().shop << endl;
        console_mutex->unlock();

        queue_mutex->unlock();

        sem_post(&shop_sems->at(shoppingList.back().shop));
        sem_wait(customer_semaphore);

        console_mutex->lock();
        cout << "Customer #" << myId << ": I have bought product #" << shoppingList.back().id <<
             " in shop #" << shoppingList.back().shop << endl;
        console_mutex->unlock();

        shoppingList.pop_back();
    }
    served_mutex->lock();
    servedCustomers++;
    served_mutex->unlock();

    console_mutex->lock();
    cout << "Customer #" << myId << ": I have bought everything I wanted!" << endl;
    cout << "Served customers: " << servedCustomers << endl;
    console_mutex->unlock();

    return;
}

void shopFunction(vector<sem_t> *shop_sems, int countOfCustomers, vector<sem_t> *customer_sems, mutex *vector_mutex,
                  mutex *console_mutex, mutex *gen_shop_mutex, mutex *served_mutex){

    gen_shop_mutex->lock();
    int myid = globalIdShop++;
    srand(static_cast<unsigned>(myid * myid + static_cast<unsigned>(time(nullptr))));
    gen_shop_mutex->unlock();

    int myServedCustomers = 0;
    int customerId;

    while(myServedCustomers != countOfCustomers){
        sem_wait(&shop_sems->at(myid));

        vector_mutex->lock();
        customerId = queues[myid].front();
        queues[myid].pop();
        vector_mutex->unlock();

        console_mutex->lock();
        cout << "The Shop #" << myid
             << " is serving the customer #" << customerId << endl;
        console_mutex->unlock();

        this_thread::sleep_for(chrono::seconds(2));

        console_mutex->lock();
        cout << "The Shop #" << myid
             << " has served the customer #" << customerId << endl;
        console_mutex->unlock();

        sem_post(&customer_sems->at(customerId));

        served_mutex->lock();
        myServedCustomers = servedCustomers;
        served_mutex->unlock();
    }
    return;
}

int main() {
    int countOfCustomers;
    int maxCountOfProducts;
    mutex queue_mutex, served_mutex, vector_mutex, console_mutex, generation_mutex, gen_shop_mutex;
    // Input
    cout << "Input count of the customers >=2:" << endl;
    cin >> countOfCustomers;
    if (countOfCustomers < 2){
        cout << "count must be >= 2!";
        return -1;
    }
    cout << "Input max count of products in the list:" << endl;
    cin >> maxCountOfProducts;
    // Customer semaphores.
    vector<sem_t> customer_semaphores(countOfCustomers);
    generateProducts(countOfCustomers, maxCountOfProducts);
    for (uint64_t i = 0; i < countOfCustomers; ++i) {
        sem_init(&customer_semaphores[i], 0, 0);
    }
    pthread_barrier_t customer_barrier;
    pthread_barrier_init(&customer_barrier, nullptr, countOfCustomers + 2);
    // Shop semaphores.
    vector<sem_t> shop_semaphores(2);
    for (auto &sem : shop_semaphores) {
        sem_init(&sem, 0, 0);
    }

    vector<thread> customer_threads;
    for (uint64_t i = 0; i < countOfCustomers; ++i) {
        customer_threads.emplace_back(customerFunction, &shop_semaphores, maxCountOfProducts, &customer_semaphores[i],
                                      &generation_mutex, &queue_mutex, &console_mutex, &served_mutex);
    }

    vector<std::thread> shop_threads;
    for (int i = 0; i < 2; ++i) {
        shop_threads.emplace_back(shopFunction, &shop_semaphores, countOfCustomers, &customer_semaphores, &vector_mutex,
                                  &console_mutex, &gen_shop_mutex, &served_mutex);
    }

    for (uint64_t i = 0; i < 2; ++i) {
        shop_threads[i].detach();
    }
    for (uint64_t i = 0; i < countOfCustomers; ++i) {
        customer_threads[i].join();
    }

    system ("pause");
    return 0;
}
