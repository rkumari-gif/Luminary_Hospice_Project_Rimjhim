{% macro hash_key_generator(cols = []) %}
    SHA2(
    {%- for col in cols -%}
        {{ "coalesce(cast(trim(" ~  col ~ ") as string),'') "  }}
        {%- if not loop.last -%}||'-'|| {% endif %}
    {% endfor -%}
    )
{% endmacro %}
