{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is not none -%}
        {# If a custom schema like '_gold' is defined, use it directly #}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {# Fall back to the default target schema in profiles.yml #}
        {{ target.schema }}
    {%- endif -%}
{%- endmacro %}