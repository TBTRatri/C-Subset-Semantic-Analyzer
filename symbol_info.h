#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <iostream>
#include <string>
#include <vector>

using namespace std;

class symbol_info {
private:
    string name;
    string type;      // e.g., "ID", "CONST_INT"
    string data_type; // Lab 3 er jonno ekhon "int", "float", ba "void" [cite: 19]
    
    // Array related [cite: 26]
    bool is_array = false;
    int array_size = 0; 

    // Function related [cite: 28]
    bool is_function = false;
    string return_type; 
    vector<pair<string, string>> parameters; // {type, name} format 

public:
    // Constructors
    symbol_info(string name, string type) : name(name), type(type) {}
    
    symbol_info(string name, string type, string data_type)
        : name(name), type(type), data_type(data_type) {}
    
    symbol_info(string name, string type, string data_type, int array_size)
        : name(name), type(type), data_type(data_type), array_size(array_size), is_array(true) {}

    // Getters [cite: 31]
    string getname() const { return name; }
    string gettype() const { return type; }
    string get_data_type() const { return data_type; }
    bool get_is_array() const { return is_array; }
    int get_array_size() const { return array_size; }
    bool get_is_function() const { return is_function; }
    string get_return_type() const { return return_type; }
    vector<pair<string, string>> get_parameters() const { return parameters; }

    // Setters
    void set_data_type(const string &data_type) { this->data_type = data_type; }
    void set_array_size(int size) { this->array_size = size; this->is_array = true; }
    
    void set_as_function(const string &ret_type, const vector<pair<string, string>> &params) {
        this->is_function = true;
        this->return_type = ret_type; //
        this->parameters = params; //
    }

    ~symbol_info() {} 
};

#endif
