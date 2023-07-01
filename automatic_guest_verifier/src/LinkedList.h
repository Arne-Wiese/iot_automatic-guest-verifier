#ifndef LINKEDLIST_H
#define LINKEDLIST_H

#include <stdbool.h>

#define MAX_L 10

typedef struct Node {
    char data[30]; // Assuming each node can store a string of maximum length 20
    struct Node* next;
} Node;

typedef struct {
    Node nodes[MAX_L];
    Node* head;
    int size;
} LinkedList;

void initializeLinkedList(LinkedList* list);
void insert(LinkedList* list, const char* data);
bool removeElement(LinkedList* list, const char* data);
void displayLinkedList(const LinkedList* list);
bool findListElement(const LinkedList* list, const char* data);

#endif  // LINKEDLIST_H