using UnityEngine;
using UnityEditor;
using System;

public class ShowIfDrawer : MaterialPropertyDrawer
{
    private string keyword;
    public ShowIfDrawer(string text)
    {
        this.keyword = text;
    }

    public override void OnGUI(Rect position, MaterialProperty prop, String label, MaterialEditor editor)
    {
        bool show = false;
        foreach(Material material in prop.targets)
        {
            if (material.IsKeywordEnabled(keyword))
            {
                show = true;
                break;
            }
        }
        // Setup
        bool value = (prop.floatValue != 0.0f);

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = prop.hasMixedValue;

        // Show the toggle control
        if (show)
        {
            base.OnGUI(position,prop,label,editor);
            //value = EditorGUI.Toggle(position, label, value);
            
            
        }
        

        EditorGUI.showMixedValue = false;
        if (EditorGUI.EndChangeCheck())
        {
            // Set the new value if it has changed
            prop.floatValue = value ? 1.0f : 0.0f;
        }
    }

    public override void Apply(MaterialProperty prop)
    {
        Debug.Log("Applying");
        base.Apply(prop);
    }
}
