package training.ds.stack;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class Reconciler {

    private class PendingTransaction{
        long getId(){
            return 0;
        }
    }

    private class ProcessedTransaction{
        Optional<String> status;

        Optional<String> getStatus(){
            return status;
        }

        String getId(){
            return "";
        }
    }

    Stream<PendingTransaction> reconcile(Stream<PendingTransaction> pending, Stream<Stream<ProcessedTransaction>> processed) {
        if(pending == null || processed == null) {
            return Stream.empty();
        }
        Set<Long> filteredProcessedId = processed
                .flatMap(p -> p)
                .filter(Objects::nonNull)
                .filter(p -> p.getStatus().isPresent() && "DONE".equals(p.getStatus().orElseGet(null)))
                .filter(p -> p.getId() != null && p.getId().length() > 0)
                .map(p -> Long.parseLong(p.getId())).collect(Collectors.toSet());

        return pending.filter(p -> !filteredProcessedId.contains(p.getId()));
    }


}
