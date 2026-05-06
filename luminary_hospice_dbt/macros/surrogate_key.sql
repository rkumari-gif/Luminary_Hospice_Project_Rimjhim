{% macro surrogate_key(field_list) %}
    {{ hash_key_generator(field_list) }}
{% endmacro %}
