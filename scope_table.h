#ifndef SCOPE_TABLE_H
#define SCOPE_TABLE_H

#include "symbol_info.h"
#include <list>
#include <vector>
#include <fstream>
#include <string>

using namespace std;

class scope_table {
private:
    int bucket_count; 
    int unique_id;    
    scope_table *parent_scope = nullptr; 
    vector<list<symbol_info *>> table;

    int hash_function(const string &name) {
        int s = 0;
        for (char x : name) {
            s += (int)x;
        }
        return s % bucket_count; 
    }

public:
    scope_table(int n, int id, scope_table *parent)
        : bucket_count(n), unique_id(id), parent_scope(parent) {
        table.resize(bucket_count);
    }

    ~scope_table() {
        for (int i = 0; i < bucket_count; i++) {
            for (auto symbol : table[i]) {
                delete symbol;
            }
            table[i].clear();
        }
    }

    scope_table *get_parent_scope() { return parent_scope; }
    int get_unique_id() { return unique_id; }

    symbol_info *lookup_in_scope(string name) {
        int hash_val = hash_function(name);
        for (symbol_info *current : table[hash_val]) {
            if (current->getname() == name) {
                return current;
            }
        }
        return nullptr;
    }

    bool insert_in_scope(symbol_info *symbol) {
        if (lookup_in_scope(symbol->getname()) != nullptr) {
            return false; 
        }
        int hash_val = hash_function(symbol->getname());
        table[hash_val].push_back(symbol);
        return true;
    }

    bool delete_from_scope(string name) {
        int hash_val = hash_function(name);
        for (auto it = table[hash_val].begin(); it != table[hash_val].end(); ++it) {
            if ((*it)->getname() == name) {
                delete *it; 
                table[hash_val].erase(it);
                return true;
            }
        }
        return false;
    }

    // Lab 3: Print format ektu clean kora hoyeche sample output match korar jonno
    void print_scope_table(ofstream &outlog) {
        outlog << "ScopeTable # " << unique_id << endl;
        for (int i = 0; i < bucket_count; i++) {
            if (!table[i].empty()) {
                outlog << " " << i << " --> ";
                for (auto current : table[i]) {
                    // Ekhane ID er sathe Type print hobe
                    outlog << "< " << current->getname() << " : " << current->get_data_type() << " > ";
                }
                outlog << endl;
            }
        }
        outlog << endl;
    }
};

#endif
