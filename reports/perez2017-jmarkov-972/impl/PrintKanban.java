// Harness for the registered claim (queue/perez2017-jmarkov-972.json): prints the first average
// measure of performance of the authors' Kanban model, as KanbanTest.testGetMOPsAvg computes it.
// It calls the authors' method with the authors' default parameters and adds no model code.
// Written by the rerun mind; CC0.
import examples.jmarkov.Kanban;

public class PrintKanban {
    public static void main(String[] args) throws Exception {
        Kanban kaby = new Kanban();
        kaby.setDebugLevel(0);
        double[] mops = kaby.getMOPsAvg();
        System.out.println("MOPS_AVG[0] " + mops[0]);
        System.out.println("VALUE Kanban MOPs avg [0] " + mops[0]);
    }
}
