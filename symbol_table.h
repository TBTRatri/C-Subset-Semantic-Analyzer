#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "scope_table.h"
#include <iostream>

using namespace std;

class symbol_table {
private:
    scope_table *current_scope;
    int bucket_count;
    int scope_count; 

public:
    symbol_table(int bucket_count) : bucket_count(bucket_count), scope_count(1) {
        current_scope = new scope_table(bucket_count, scope_count, nullptr);
    }

    ~symbol_table() {
        while (current_scope != nullptr) {
            scope_table *temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }

    void enter_scope() {
        scope_table *new_scope = new scope_table(bucket_count, ++scope_count, current_scope);
        current_scope = new_scope;
    }

    void exit_scope() {
        if (current_scope == nullptr) return;
        scope_table *temp = current_scope;
        current_scope = current_scope->get_parent_scope();
        delete temp;
    }

    bool insert(symbol_info *symbol) {
        if (current_scope != nullptr) {
            return current_scope->insert_in_scope(symbol); //
        }
        return false;
    }

    symbol_info *lookup(string name) {
        scope_table *temp = current_scope;
        while (temp != nullptr) {
            symbol_info *found = temp->lookup_in_scope(name); //
            if (found != nullptr) return found;
            temp = temp->get_parent_scope(); //
        }
        return nullptr;
    }

    symbol_info *lookup_current_scope(string name) {
        if (current_scope != nullptr) {
            return current_scope->lookup_in_scope(name);
        }
        return nullptr;
    }

    void print_all_scopes(ofstream &out) {
        scope_table *temp = current_scope;
        while (temp != nullptr) {
            temp->print_scope_table(out); //
            temp = temp->get_parent_scope();
        }
    }

    int get_current_scope_id() {
        return (current_scope != nullptr) ? current_scope->get_unique_id() : 0;
    }
};

#endif
