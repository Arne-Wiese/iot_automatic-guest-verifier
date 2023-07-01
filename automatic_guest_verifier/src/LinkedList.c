#include "LinkedList.h"
#include <stdio.h>
#include <string.h>

void initializeLinkedList(LinkedList* list) {
    list->head = NULL;
    list->size = 0;
}

void insert(LinkedList* list, const char* data) {
    if (list->size >= MAX_L) {
        printf("LinkedList is full. Unable to insert new element.\n");
        return;
    }

    Node* newNode = &list->nodes[list->size];
    strncpy(newNode->data, data, sizeof(newNode->data) - 1);
    newNode->data[sizeof(newNode->data) - 1] = '\0'; // Ensure null-terminated string
    newNode->next = list->head;
    list->head = newNode;
    list->size++;
}

bool removeElement(LinkedList* list, const char* data) {
    if (list->head == NULL){
        return false;
    }

    Node* current = list->head;
    Node* previous = NULL;

    while (current != NULL) {
        if (strcmp(current->data, data) == 0) {
            if (previous == NULL) {
                list->head = current->next;
            } else {
                previous->next = current->next;
            }
            list->size--;
            return true;
        }

        previous = current;
        current = current->next;
    }

    return false;
}

void displayLinkedList(const LinkedList* list) {
    if (list->head == NULL) {
        printf("LinkedList is empty.\n");
        return;
    }

    Node* current = list->head;

    while (current != NULL) {
        printf("%s\n", current->data);
        current = current->next;
    }
}

bool findListElement(const LinkedList* list, const char* data) {
    if (list->head == NULL)
        return false;

    Node* current = list->head;

    while (current != NULL) {
        if (strcmp(current->data, data) == 0)
            return true;

        current = current->next;
    }

    return false;
}
